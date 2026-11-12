import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/tv_shell.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

Future<FocusNode> _pump(
  WidgetTester tester, {
  required void Function(String) onNavigate,
  required VoidCallback onExit,
}) async {
  final content = FocusNode();
  await tester.pumpWidget(
    MaterialApp(
      home: TvShell(
        location: '/tv/home',
        onNavigate: onNavigate,
        onExit: onExit,
        child: Center(
          child: TvFocusable(
            focusNode: content,
            autofocus: true,
            onSelect: () {},
            child: const SizedBox(width: 200, height: 200),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return content;
}

void main() {
  testWidgets('arrow left from content moves focus to the rail', (
    tester,
  ) async {
    final content = await _pump(tester, onNavigate: (_) {}, onExit: () {});
    expect(content.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(content.hasFocus, isFalse);
    expect(FocusManager.instance.primaryFocus, isNotNull);
  });

  testWidgets('arrow left works when content sits in a nested navigator', (
    tester,
  ) async {
    final content = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: TvShell(
          location: '/tv/home',
          onNavigate: (_) {},
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => Center(
                child: TvFocusable(
                  focusNode: content,
                  autofocus: true,
                  onSelect: () {},
                  child: const SizedBox(width: 200, height: 200),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(content.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(content.hasFocus, isFalse);
  });

  testWidgets('Back in content focuses the rail, Back on the rail exits', (
    tester,
  ) async {
    var exited = 0;
    final content = await _pump(
      tester,
      onNavigate: (_) {},
      onExit: () => exited++,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(content.hasFocus, isFalse);
    expect(exited, 0);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exited, 1);
  });

  testWidgets('selecting a rail item calls onNavigate with its path', (
    tester,
  ) async {
    final paths = <String>[];
    await _pump(tester, onNavigate: paths.add, onExit: () {});
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(paths, hasLength(1));
    expect(paths.single, startsWith('/tv/'));
  });
}
