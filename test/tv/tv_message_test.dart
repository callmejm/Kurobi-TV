import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';

void main() {
  testWidgets('action button is focused and OK triggers it (no rules case)', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TvMessage(
            text: '还没有规则',
            actionLabel: '去安装规则',
            onAction: () => opened++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(opened, 1);
  });

  testWidgets('message without action renders no button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TvMessage(text: '还没有收藏')),
      ),
    );
    expect(find.text('还没有收藏'), findsOneWidget);
    expect(find.byType(GestureDetector), findsNothing);
  });
}
