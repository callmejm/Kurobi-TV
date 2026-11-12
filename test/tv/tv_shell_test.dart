import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/tv_shell.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

/// Shell whose page sits in a nested navigator, like the RouterOutlet.
Future<FocusNode> _pump(
  WidgetTester tester, {
  void Function(String)? onNavigate,
  VoidCallback? onExit,
  String location = '/tv/home',
}) async {
  final content = FocusNode(debugLabel: 'content');
  await tester.binding.setSurfaceSize(const Size(960, 540));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTvTheme(),
      home: TvShell(
        location: location,
        onNavigate: onNavigate ?? (_) {},
        onExit: onExit ?? () {},
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => Padding(
              padding: TvTokens.pagePadding,
              child: Align(
                alignment: Alignment.topLeft,
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
    ),
  );
  await tester.pump();
  return content;
}

void main() {
  testWidgets('up from the top of a page moves focus to the nav bar', (
    tester,
  ) async {
    final content = await _pump(tester);
    expect(content.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(content.hasFocus, isFalse);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav 首页');
  });

  testWidgets('down from the nav bar enters the page', (tester) async {
    final content = await _pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(content.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(content.hasFocus, isTrue);
  });

  testWidgets('Back in content focuses the nav bar, Back on it exits', (
    tester,
  ) async {
    var exited = 0;
    final content = await _pump(tester, onExit: () => exited++);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(content.hasFocus, isFalse);
    expect(exited, 0);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exited, 1);
  });

  testWidgets('Back on another tab goes home before exiting', (tester) async {
    var exited = 0;
    final paths = <String>[];
    await _pump(
      tester,
      location: '/tv/timeline',
      onNavigate: paths.add,
      onExit: () => exited++,
    );

    await tester.binding.handlePopRoute(); // content -> nav
    await tester.pump();
    await tester.binding.handlePopRoute(); // nav on 时间表 -> home
    await tester.pump();
    expect(paths, ['/tv/home']);
    expect(exited, 0);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav 首页');
  });

  testWidgets('left and right walk the nav bar one tab at a time', (
    tester,
  ) async {
    await _pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    final labels = <String?>[];
    for (final key in [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowRight,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      labels.add(FocusManager.instance.primaryFocus?.debugLabel);
    }
    expect(labels, [
      'nav 搜索',
      'nav 首页',
      'nav 时间表',
      'nav 收藏',
      'nav 历史',
      'nav 规则',
      'nav 设置',
      'nav 设置',
    ]);
  });

  testWidgets('selecting a nav item calls onNavigate with its path', (
    tester,
  ) async {
    final paths = <String>[];
    await _pump(tester, onNavigate: paths.add);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(paths, ['/tv/timeline']);
  });
}
