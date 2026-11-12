import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/dialog/dialog.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/pages/video/video_playback_args.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart';
import 'package:kazumi/tv/player/tv_player_page.dart' show TvPlaybackRequest;
import 'package:kazumi/tv/tv_nsfw.dart';
import 'package:kazumi/tv/tv_routes.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_backdrop.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_headline.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_source_picker.dart';
import 'package:kazumi/utils/format.dart';

/// Anime detail: cover, summary, tags (each opens a tag search), "watch"
/// (opens the source picker) and a collect button that opens a list of the
/// collect types. Once watched, "continue" reopens the last source at the
/// saved episode and position, and "change source" opens the picker.
class TvInfoPage extends StatefulWidget {
  const TvInfoPage({
    super.key,
    required this.bangumiItem,
    required this.infoController,
    required this.pluginsController,
    required this.collectController,
    required this.historyController,
  });

  final BangumiItem bangumiItem;
  final InfoController infoController;
  final PluginsController pluginsController;
  final CollectController collectController;
  final HistoryController historyController;

  @override
  State<TvInfoPage> createState() => _TvInfoPageState();
}

class _TvInfoPageState extends State<TvInfoPage> {
  InfoController get _info => widget.infoController;

  @override
  void initState() {
    super.initState();
    _info.bangumiItem = widget.bangumiItem;
    _info.pluginSearchResponseList.clear();
    if (widget.bangumiItem.summary.isEmpty) {
      _info.queryBangumiInfoByID(widget.bangumiItem.id).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  CollectType get _collectType => CollectType.fromValue(
    widget.collectController.getCollectType(_info.bangumiItem),
  );

  Future<void> _pickCollect() async {
    final current = _collectType;
    final picked = await showDialog<CollectType>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: TvTokens.surfaceHigh,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('追番', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              for (final type in CollectType.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TvButton(
                    label: type.label,
                    selected: type == current,
                    autofocus: type == current,
                    onSelect: () => Navigator.of(dialogContext).pop(type),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == current) return;
    await widget.collectController.addCollect(
      _info.bangumiItem,
      type: picked.value,
    );
    if (mounted) setState(() {});
  }

  bool _resuming = false;

  /// The latest online watch of this anime whose rule is still installed.
  History? get _lastWatch {
    final installed = {
      for (final p in widget.pluginsController.pluginList) p.name,
    };
    History? last;
    for (final h in widget.historyController.histories) {
      if (h.bangumiItem.id != _info.bangumiItem.id ||
          h.entryKind != HistoryEntryKind.online ||
          h.lastSrc.isEmpty ||
          !installed.contains(h.adapterName)) {
        continue;
      }
      if (last == null || h.lastWatchTime.isAfter(last.lastWatchTime)) {
        last = h;
      }
    }
    return last;
  }

  /// Reopens [last]'s source without searching; the player then seeks to the
  /// saved position of the episode.
  Future<void> _resume(History last) async {
    if (_resuming) return;
    final plugin = widget.pluginsController.pluginList.firstWhere(
      (p) => p.name == last.adapterName,
    );
    setState(() => _resuming = true);
    try {
      final roads = await plugin.queryChapterRoads(
        last.lastSrc,
        cancelToken: RuleCancelToken(),
      );
      if (!mounted) return;
      final item = _info.bangumiItem;
      final progress = widget.historyController.lastWatching(item, plugin.name);
      var road = progress?.road ?? 0;
      var episode = progress?.episode ?? last.lastWatchEpisode;
      if (road >= roads.length || episode > roads[road].data.length) {
        road = 0;
        episode = 1;
      }
      if (roads.isEmpty || roads[road].data.isEmpty) {
        KazumiDialog.showToast(message: '${plugin.name} 没有可播放的剧集，请按「换源」');
        return;
      }
      context.pushNamed(
        TvRoutes.video,
        arguments: TvPlaybackRequest(
          OnlineVideoPlaybackArgs(
            bangumiItem: item,
            plugin: plugin,
            title: item.nameCn.isEmpty ? item.name : item.nameCn,
            src: last.lastSrc,
            roads: roads,
          ),
          episode: episode,
          road: road,
        ),
      );
    } on CaptchaRequiredException {
      KazumiDialog.showToast(message: '${plugin.name} 需要验证，请在手机上完成验证，或按「换源」');
    } catch (error) {
      KazumiLogger().w('TvInfoPage: failed to resume', error: error);
      KazumiDialog.showToast(message: '未能获取播放列表，请重试或按「换源」');
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
  }

  void _openSources() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: TvTokens.background,
        child: TvSourcePicker(
          infoController: _info,
          pluginsController: widget.pluginsController,
          onOpenRules: () {
            Navigator.of(dialogContext).pop();
            context.navigate(TvRoutes.rules);
          },
          onPlay: (request) {
            Navigator.of(dialogContext).pop();
            context.pushNamed(TvRoutes.video, arguments: request);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _info.bangumiItem;
    final collected = _collectType != CollectType.none;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          TvBackdrop(imageUrl: item.images['large'] ?? ''),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvTokens.edgeH,
              TvTokens.edgeV + 40,
              TvTokens.edgeH,
              TvTokens.edgeV + 20,
            ),
            child: FractionallySizedBox(
              widthFactor: 0.56,
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvBangumiHeadline(item: item, titleLines: 2, summaryLines: 4),
                  const SizedBox(height: 24),
                  Observer(
                    builder: (_) {
                      final last = _lastWatch;
                      final progress = last == null
                          ? null
                          : widget.historyController.lastWatching(
                              _info.bangumiItem,
                              last.adapterName,
                            );
                      final episode =
                          progress?.episode ?? last?.lastWatchEpisode ?? 0;
                      // Position, plus the length once a player has saved it.
                      final time = progress == null
                          ? ''
                          : '  ${durationToString(progress.progress)}'
                                '${progress.durationMs > 0 ? ' / ${durationToString(progress.duration)}' : ''}';
                      return Row(
                        children: [
                          if (last == null)
                            TvButton(
                              icon: Icons.play_arrow_rounded,
                              label: '开始观看',
                              selected: true,
                              autofocus: true,
                              onSelect: _openSources,
                            )
                          else ...[
                            TvButton(
                              icon: Icons.play_arrow_rounded,
                              label: _resuming
                                  ? '正在获取播放列表…'
                                  : '继续播放 第$episode集$time',
                              selected: true,
                              autofocus: true,
                              onSelect: () => _resume(last),
                            ),
                            const SizedBox(width: 12),
                            TvButton(
                              icon: Icons.swap_horiz_rounded,
                              label: '换源',
                              onSelect: _openSources,
                            ),
                          ],
                          const SizedBox(width: 12),
                          TvButton(
                            icon: collected
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: collected ? _collectType.label : '追番',
                            onSelect: _pickCollect,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Tags below the actions, quieter than them; OK searches
                  // the tag. Scrolls when there are more than fit.
                  Expanded(
                    child: SingleChildScrollView(
                      // Room for the focus scale inside the clip.
                      padding: const EdgeInsets.all(4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in item.tags.where(
                            (t) => tvShowNsfw.value || !isNsfwTag(t.name),
                          ))
                            TvButton(
                              label: '${tag.name} ${tag.count}',
                              onSelect: () => context.pushNamed(
                                TvRoutes.tagSearch,
                                arguments: tag.name,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
