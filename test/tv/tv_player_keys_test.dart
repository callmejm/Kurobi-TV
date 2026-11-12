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

  test('play and pause media keys are not toggles', () {
    expect(_action(LogicalKeyboardKey.mediaPlay), TvPlayerAction.play);
    expect(_action(LogicalKeyboardKey.mediaPause), TvPlayerAction.pause);
  });

  group('SeekScrubber', () {
    const position = Duration(minutes: 5);
    const duration = Duration(minutes: 24);

    test('presses add up from the playing position', () {
      final scrubber = SeekScrubber();
      scrubber.nudge(1, position: position, duration: duration);
      final target = scrubber.nudge(1, position: position, duration: duration);
      expect(target, const Duration(minutes: 5, seconds: 20));
    });

    test('holding speeds up the step', () {
      final scrubber = SeekScrubber();
      Duration target = position;
      for (var i = 0; i < 6; i++) {
        target = scrubber.nudge(1, position: position, duration: duration);
      }
      // 4 x 10 s, then 30 s steps.
      expect(target, const Duration(minutes: 6, seconds: 40));
    });

    test('target stays inside the video', () {
      final scrubber = SeekScrubber();
      expect(
        scrubber.nudge(
          -1,
          position: const Duration(seconds: 3),
          duration: duration,
        ),
        Duration.zero,
      );
      final end = SeekScrubber();
      expect(
        end.nudge(
          1,
          position: const Duration(minutes: 23, seconds: 58),
          duration: duration,
        ),
        duration,
      );
    });

    test('commit returns the target once and resets', () {
      final scrubber = SeekScrubber();
      scrubber.nudge(-1, position: position, duration: duration);
      expect(scrubber.commit(), const Duration(minutes: 4, seconds: 50));
      expect(scrubber.target, isNull);
      expect(scrubber.commit(), isNull);
      expect(
        scrubber.nudge(1, position: position, duration: duration),
        const Duration(minutes: 5, seconds: 10),
      );
    });
  });
}
