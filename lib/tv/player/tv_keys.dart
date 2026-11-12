import 'package:flutter/services.dart';

enum TvPlayerAction {
  playPause,
  play,
  pause,
  seekBack,
  seekForward,
  showControls,
  openEpisodes,
  back,
  none,
}

/// Maps a remote key to a player action. While the episode list is open it
/// owns arrows and OK, so only Back is handled here.
TvPlayerAction tvPlayerActionFor(
  LogicalKeyboardKey key, {
  required bool controlsVisible,
  required bool episodesOpen,
}) {
  if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
    return TvPlayerAction.back;
  }
  if (episodesOpen) return TvPlayerAction.none;
  if (key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.mediaRewind) {
    return TvPlayerAction.seekBack;
  }
  if (key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.mediaFastForward) {
    return TvPlayerAction.seekForward;
  }
  if (key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.mediaPlayPause) {
    return TvPlayerAction.playPause;
  }
  if (key == LogicalKeyboardKey.mediaPlay) return TvPlayerAction.play;
  if (key == LogicalKeyboardKey.mediaPause) return TvPlayerAction.pause;
  if (key == LogicalKeyboardKey.arrowUp) {
    return controlsVisible ? TvPlayerAction.none : TvPlayerAction.showControls;
  }
  if (key == LogicalKeyboardKey.arrowDown) return TvPlayerAction.openEpisodes;
  return TvPlayerAction.none;
}

/// Adds up D-pad seek presses into one target so the player seeks once, after
/// the user stops pressing. Holding the key grows the step: 10 s, then 30 s,
/// then 60 s.
class SeekScrubber {
  Duration? _target;
  int _presses = 0;

  Duration? get target => _target;

  Duration nudge(
    int direction, {
    required Duration position,
    required Duration duration,
  }) {
    final seconds = _presses < 4 ? 10 : (_presses < 12 ? 30 : 60);
    _presses++;
    var next = (_target ?? position) + Duration(seconds: seconds * direction);
    if (next < Duration.zero) next = Duration.zero;
    if (duration > Duration.zero && next > duration) next = duration;
    return _target = next;
  }

  /// Returns the pending target (null if none) and starts a fresh scrub.
  Duration? commit() {
    final target = _target;
    _target = null;
    _presses = 0;
    return target;
  }
}
