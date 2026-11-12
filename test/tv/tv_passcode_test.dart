import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/widgets/tv_passcode_dialog.dart';

void main() {
  Future<String?> Function() open(WidgetTester tester, String expected) {
    String? result;
    var closed = false;
    return () async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTvPasscodeDialog(
                  context,
                  title: 'pin',
                  accept: (code) => code == expected,
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return closed ? result : 'open';
    };
  }

  Future<void> enter(WidgetTester tester, String code) async {
    for (final digit in code.split('')) {
      await tester.tap(find.text(digit));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('a wrong code stays open with an error, the right one closes', (
    tester,
  ) async {
    final state = await open(tester, '2580')();
    expect(state, 'open');

    await enter(tester, '1111');
    expect(find.text('密码错误'), findsOneWidget);
    expect(find.text('pin'), findsOneWidget);

    await enter(tester, '258');
    await tester.tap(find.text('⌫'));
    await tester.pumpAndSettle();
    await enter(tester, '80');
    expect(find.text('pin'), findsNothing);
  });
}
