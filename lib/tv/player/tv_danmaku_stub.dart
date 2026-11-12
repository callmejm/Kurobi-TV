import 'package:canvas_danmaku/canvas_danmaku.dart' as canvas;
import 'package:flutter/painting.dart';

/// Danmaku controller that draws nothing.
///
/// [PlayerController.pause]/[play] and episode changes drive
/// `danmaku.canvasController`, which the phone player's danmaku screen sets.
/// The TV player shows no danmaku, so it installs this instead; without it
/// those calls throw a LateInitializationError and OK cannot pause.
canvas.DanmakuController tvNoDanmakuController() {
  var option = const canvas.DanmakuOption();
  return canvas.DanmakuController(
    addDanmaku: (_) {},
    updateOption: (value) => option = value,
    pause: () {},
    resume: () {},
    clear: () {},
    getOption: () => option,
    isRunning: () => false,
    findDanmaku: (Offset _) => const [],
    findSingleDanmaku: (Offset _) => null,
    getViewWidth: () => 0,
    getViewHeight: () => 0,
    scrollDanmaku: [],
    staticDanmaku: [],
    specialDanmaku: [],
  );
}
