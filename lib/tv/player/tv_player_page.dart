import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/pages/player/player_controller.dart';
import 'package:kazumi/pages/player/player_item_surface.dart';
import 'package:kazumi/pages/video/video_controller.dart';
import 'package:kazumi/pages/video/video_playback_args.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/tv/player/tv_danmaku_stub.dart';
import 'package:kazumi/tv/player/tv_keys.dart';
import 'package:kazumi/tv/player/tv_player_overlay.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';

/// Route arguments when the viewer picked an episode before playing.
class TvPlaybackRequest {
  const TvPlaybackRequest(this.args, {required this.episode, this.road = 0});

  final OnlineVideoPlaybackArgs args;

  /// 1-based, like [VideoPageController.changeEpisode].
  final int episode;
  final int road;
}

/// D-pad video player. Reuses [VideoPageController] (source resolution,
/// episode switching) and [PlayerController]; only the controls are TV-specific.
class TvPlayerPage extends StatefulWidget {
  const TvPlayerPage({
    super.key,
    required this.args,
    required this.playerController,
    required this.videoPageController,
    required this.historyController,
    this.startEpisode,
    this.startRoad = 0,
  });

  final VideoPlaybackArgs args;

  /// Episode chosen in the source picker; null resumes from history.
  final int? startEpisode;
  final int startRoad;
  final PlayerController playerController;
  final VideoPageController videoPageController;
  final HistoryController historyController;

  @override
  State<TvPlayerPage> createState() => _TvPlayerPageState();
}

class _TvPlayerPageState extends State<TvPlayerPage>
    with WidgetsBindingObserver {
  static const _seekSettle = Duration(milliseconds: 600);
  static const _controlsTimeout = Duration(seconds: 4);

  final _focus = FocusNode(debugLabel: 'TV player keys');
  final _playButton = FocusNode(debugLabel: 'play button');
  final _scrubber = SeekScrubber();
  Timer? _tick;
  Timer? _hideControls;
  Timer? _seekCommit;
  bool _controlsVisible = false;
  bool _episodesOpen = false;
  bool _exiting = false;

  /// A button of the bar under the progress bar has focus.
  bool _barFocused = false;

  PlayerController get _player => widget.playerController;
  VideoPageController get _video => widget.videoPageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player.danmaku.canvasController = tvNoDanmakuController();
    _video.applyPlaybackArgs(widget.args);
    _applyResume();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _keepFocus();
      _changeEpisode(
        _video.selectedEpisode.episode,
        road: _video.selectedEpisode.road,
        offset: _video.historyOffset,
      );
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _focus.addListener(_keepFocus);
  }

  /// Closing the source picker dialog restores focus to the detail page
  /// underneath, racing this page's autofocus; keys then miss the player.
  /// Take focus back while this is the top route.
  void _keepFocus() {
    if (_focus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _exiting || _focus.hasFocus) return;
      if (ModalRoute.of(context)?.isCurrent ?? false) _focus.requestFocus();
    });
  }

  /// Resumes from the last watched episode and position, like the phone UI.
  void _applyResume() {
    _video.historyOffset = 0;
    final progress = widget.historyController.lastWatching(
      _video.bangumiItem,
      _video.currentPlugin.name,
    );
    final start = widget.startEpisode;
    if (start != null) {
      // A picked episode wins; keep the saved position only if it is that one.
      _video.resetEpisodeState(episode: start, road: widget.startRoad);
      if (progress != null &&
          progress.episode == start &&
          progress.road == widget.startRoad &&
          GStorage.getSetting(SettingsKeys.playResume)) {
        _video.historyOffset = progress.progress.inSeconds;
      }
      return;
    }
    if (progress == null ||
        _video.roadList.length <= progress.road ||
        _video.roadList[progress.road].data.length < progress.episode) {
      return;
    }
    _video.resetEpisodeState(episode: progress.episode, road: progress.road);
    if (GStorage.getSetting(SettingsKeys.playResume)) {
      _video.historyOffset = progress.progress.inSeconds;
    }
  }

  Future<void> _changeEpisode(int episode, {int road = 0, int offset = 0}) {
    if (!mounted || _exiting) return Future.value();
    return _video.changeEpisode(
      episode,
      currentRoad: road,
      offset: offset,
      playerController: _player,
    );
  }

  void _onTick() {
    if (!mounted || _exiting) return;
    _player.syncPlaybackState();
    final playback = _player.playback;
    final identity = _video.currentHistoryIdentity;
    if (playback.playerPlaying &&
        !_video.loading &&
        identity != null &&
        identity.canRecord) {
      widget.historyController.updateHistory(
        identity,
        playback.playerPosition,
        duration: playback.playerDuration,
      );
    }
    if (playback.completed && !_video.loading) {
      if (playback.resumedNearEnd) {
        // Replay a stale near-end resume instead of skipping to the next episode.
        unawaited(playback.restartFromBeginning());
      } else {
        _playNext();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Home on the remote: the surface keeps decoding in the background otherwise.
    if (state == AppLifecycleState.paused && _player.playback.playing) {
      _player.pause();
    }
  }

  void _playNext() {
    if (!GStorage.getSetting(SettingsKeys.autoPlayNext)) return;
    final playing = _video.playbackEpisode;
    if (playing.episode >= _video.roadList[playing.road].data.length) return;
    _changeEpisode(playing.episode + 1, road: playing.road);
  }

  void _showControls() {
    _hideControls?.cancel();
    _hideControls = Timer(_controlsTimeout, () {
      if (mounted) _closeControls();
    });
    if (!_controlsVisible) setState(() => _controlsVisible = true);
  }

  /// Hides the controls, taking focus back from the button bar first.
  void _closeControls() {
    if (_barFocused) _focus.requestFocus();
    setState(() => _controlsVisible = false);
  }

  void _openEpisodes() {
    _hideControls?.cancel();
    _focus.requestFocus();
    setState(() {
      _controlsVisible = false;
      _episodesOpen = true;
    });
  }

  /// Plays the episode [delta] away from the playing one, within its road.
  void _stepEpisode(int delta) {
    final playing = _video.playbackEpisode;
    final next = playing.episode + delta;
    if (next < 1 || next > _video.roadList[playing.road].data.length) return;
    _changeEpisode(next, road: playing.road);
  }

  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  void _cycleSpeed() {
    final i = _speeds.indexOf(_player.playback.playerSpeed);
    _player.setPlaybackSpeed(_speeds[(i + 1) % _speeds.length]);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    // Android Back arrives as a route pop (PopScope); handling the key too
    // would run Back twice.
    if (event.logicalKey == LogicalKeyboardKey.goBack) {
      return KeyEventResult.ignored;
    }
    final action = tvPlayerActionFor(
      event.logicalKey,
      controlsVisible: _controlsVisible,
      episodesOpen: _episodesOpen,
      barFocused: _barFocused,
    );
    // The error message owns arrows and OK so its retry button is reachable.
    if (_video.errorMessage != null && action != TvPlayerAction.back) {
      return KeyEventResult.ignored;
    }
    switch (action) {
      case TvPlayerAction.none:
        // The bar's buttons take the key; any key keeps the controls up.
        if (_barFocused) _showControls();
        return KeyEventResult.ignored;
      case TvPlayerAction.seekBack:
      case TvPlayerAction.seekForward:
        // Presses and key repeats move a target; the player seeks once the
        // remote rests, instead of once per press.
        final playback = _player.playback;
        _scrubber.nudge(
          action == TvPlayerAction.seekBack ? -1 : 1,
          position: playback.currentPosition,
          duration: playback.duration,
        );
        _showControls();
        setState(() {});
        _seekCommit?.cancel();
        _seekCommit = Timer(_seekSettle, _commitSeek);
      case TvPlayerAction.playPause:
        if (event is KeyDownEvent) {
          _showControls();
          _player.playOrPause();
        }
      case TvPlayerAction.play:
        if (event is KeyDownEvent) _player.play();
      case TvPlayerAction.pause:
        if (event is KeyDownEvent) {
          _showControls();
          _player.pause();
        }
      case TvPlayerAction.showControls:
        _showControls();
      case TvPlayerAction.focusBar:
        _showControls();
        // The bar is built on the next frame when the controls were hidden.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _controlsVisible) _playButton.requestFocus();
        });
      case TvPlayerAction.leaveBar:
        _focus.requestFocus();
        _showControls();
      case TvPlayerAction.back:
        if (event is KeyDownEvent) _back();
    }
    return KeyEventResult.handled;
  }

  void _commitSeek() {
    final target = _scrubber.commit();
    if (!mounted || target == null) return;
    setState(() {});
    _player.seek(target);
    _showControls();
  }

  /// Back closes the episode list, then the controls, then leaves the page.
  void _back() {
    if (_episodesOpen) {
      setState(() => _episodesOpen = false);
      _focus.requestFocus();
    } else if (_controlsVisible) {
      _hideControls?.cancel();
      _closeControls();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _hideControls?.cancel();
    _seekCommit?.cancel();
    _focus.dispose();
    _playButton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_episodesOpen && !_controlsVisible,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          setState(() => _exiting = true);
          _player.beginShutdown();
        } else {
          _back();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: _exiting
              ? const SizedBox.expand()
              : Observer(builder: (_) => _body()),
        ),
      ),
    );
  }

  Widget _actionBar(bool playing, double speed) {
    const gap = SizedBox(width: 12);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => _barFocused = focused,
      child: FocusTraversalGroup(
        child: Row(
          children: [
            TvButton(
              icon: Icons.skip_previous_rounded,
              label: '上一集',
              onSelect: () => _stepEpisode(-1),
            ),
            gap,
            TvButton(
              focusNode: _playButton,
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: playing ? '暂停' : '播放',
              onSelect: _player.playOrPause,
            ),
            gap,
            TvButton(
              icon: Icons.skip_next_rounded,
              label: '下一集',
              onSelect: () => _stepEpisode(1),
            ),
            gap,
            TvButton(
              icon: Icons.format_list_numbered_rounded,
              label: '选集',
              onSelect: _openEpisodes,
            ),
            gap,
            TvButton(
              icon: Icons.speed_rounded,
              label: '倍速 ${speed}x',
              onSelect: _cycleSpeed,
            ),
          ],
        ),
      ),
    );
  }

  List<String> _episodeLabels() {
    final road = _video.roadList[_video.selectedEpisode.road];
    return tvEpisodeLabels(road.identifier, road.data.length);
  }

  /// Each overlay observes only what it shows: the video surface must not
  /// rebuild on every position update.
  Widget _body() {
    final error = _video.errorMessage;
    if (error != null) {
      return TvMessage(
        text: '暂时无法播放：$error',
        actionLabel: '重试',
        onAction: () => _changeEpisode(
          _video.selectedEpisode.episode,
          road: _video.selectedEpisode.road,
        ),
      );
    }
    final muted = Theme.of(
      context,
    ).textTheme.titleMedium!.copyWith(color: TvTokens.textMuted);
    return Stack(
      fit: StackFit.expand,
      children: [
        PlayerItemSurface(playerController: _player),
        Observer(
          builder: (_) {
            final playback = _player.playback;
            if (_video.loading || playback.loading) {
              return Align(
                alignment: const Alignment(0, 0.35),
                child: Text(
                  _video.loading ? '正在解析视频地址…' : '正在缓冲…',
                  style: muted,
                ),
              );
            }
            if (!playback.playing && !_controlsVisible && !_episodesOpen) {
              return const TvPausedBadge();
            }
            return const SizedBox.shrink();
          },
        ),
        if (_controlsVisible)
          Observer(
            builder: (_) {
              final playback = _player.playback;
              final episode = _video.selectedEpisode.episode;
              final labels = _episodeLabels();
              return TvPlayerControls(
                title: _video.title,
                subtitle: episode - 1 < labels.length
                    ? labels[episode - 1]
                    : '第 $episode 集',
                position: playback.currentPosition,
                duration: playback.duration,
                playing: playback.playing,
                seekTarget: _scrubber.target,
                actions: _actionBar(playback.playing, playback.playerSpeed),
              );
            },
          ),
        if (_episodesOpen)
          TvEpisodeList(
            labels: _episodeLabels(),
            selectedIndex: _video.selectedEpisode.episode - 1,
            onSelect: (index) {
              setState(() => _episodesOpen = false);
              _focus.requestFocus();
              _changeEpisode(index + 1, road: _video.selectedEpisode.road);
            },
          ),
      ],
    );
  }
}
