import 'package:canvas_danmaku/canvas_danmaku.dart' as canvas;
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/player/tv_danmaku_stub.dart';

void main() {
  test('stub danmaku controller accepts every call the player makes', () {
    final controller = tvNoDanmakuController();
    controller.pause();
    controller.resume();
    controller.clear();
    controller.addDanmaku(canvas.DanmakuContentItem('x'));
    controller.updateOption(controller.option.copyWith(duration: 5));
    expect(controller.running, isFalse);
    expect(controller.findDanmaku(Offset.zero), isEmpty);
  });
}
