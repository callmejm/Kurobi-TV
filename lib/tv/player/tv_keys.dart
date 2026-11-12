import 'package:flutter/services.dart';

enum TvPlayerAction {
  playPause,
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
      key == LogicalKeyboardKey.mediaPlayPause ||
      key == LogicalKeyboardKey.mediaPlay ||
      key == LogicalKeyboardKey.mediaPause) {
    return TvPlayerAction.playPause;
  }
  if (key == LogicalKeyboardKey.arrowUp) {
    return controlsVisible ? TvPlayerAction.none : TvPlayerAction.showControls;
  }
  if (key == LogicalKeyboardKey.arrowDown) return TvPlayerAction.openEpisodes;
  return TvPlayerAction.none;
}

/// Limits held-key repeats so seeking does not flood the player.
class SeekThrottle {
  SeekThrottle(this.interval);

  final Duration interval;
  DateTime? _last;

  bool allow(DateTime now) {
    final last = _last;
    if (last != null && now.difference(last) < interval) return false;
    _last = now;
    return true;
  }
}
