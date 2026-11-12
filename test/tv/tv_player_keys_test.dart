import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/player/tv_keys.dart';

TvPlayerAction _action(
  LogicalKeyboardKey key, {
  bool controlsVisible = false,
  bool episodesOpen = false,
}) => tvPlayerActionFor(
  key,
  controlsVisible: controlsVisible,
  episodesOpen: episodesOpen,
);

void main() {
  test('left and right map to seek back and forward', () {
    expect(_action(LogicalKeyboardKey.arrowLeft), TvPlayerAction.seekBack);
    expect(_action(LogicalKeyboardKey.arrowRight), TvPlayerAction.seekForward);
    expect(_action(LogicalKeyboardKey.mediaRewind), TvPlayerAction.seekBack);
    expect(
      _action(LogicalKeyboardKey.mediaFastForward),
      TvPlayerAction.seekForward,
    );
  });

  test('OK, Enter and media keys toggle play and pause', () {
    for (final key in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.mediaPlayPause,
      LogicalKeyboardKey.mediaPlay,
      LogicalKeyboardKey.mediaPause,
    ]) {
      expect(_action(key), TvPlayerAction.playPause, reason: key.keyLabel);
    }
  });

  test('up shows controls only when they are hidden', () {
    expect(_action(LogicalKeyboardKey.arrowUp), TvPlayerAction.showControls);
    expect(
      _action(LogicalKeyboardKey.arrowUp, controlsVisible: true),
      TvPlayerAction.none,
    );
  });

  test('down opens the episode list', () {
    expect(_action(LogicalKeyboardKey.arrowDown), TvPlayerAction.openEpisodes);
  });

  test('Escape and GoBack map to back', () {
    expect(_action(LogicalKeyboardKey.escape), TvPlayerAction.back);
    expect(_action(LogicalKeyboardKey.goBack), TvPlayerAction.back);
  });

  test('with the episode list open, arrows and OK are left to the list', () {
    for (final key in [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.enter,
    ]) {
      expect(_action(key, episodesOpen: true), TvPlayerAction.none);
    }
    expect(
      _action(LogicalKeyboardKey.escape, episodesOpen: true),
      TvPlayerAction.back,
    );
  });

  test('unmapped keys do nothing', () {
    expect(_action(LogicalKeyboardKey.keyA), TvPlayerAction.none);
  });

  test('SeekThrottle allows one seek per interval', () {
    final throttle = SeekThrottle(const Duration(milliseconds: 250));
    final t0 = DateTime(2026, 1, 1);
    expect(throttle.allow(t0), isTrue);
    expect(throttle.allow(t0.add(const Duration(milliseconds: 100))), isFalse);
    expect(throttle.allow(t0.add(const Duration(milliseconds: 300))), isTrue);
  });
}
