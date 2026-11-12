import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

bool _hasRing(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(TvFocusable),
          matching: find.byType(DecoratedBox),
        ),
      )
      .any((box) {
        final decoration = box.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      });
}

void main() {
  testWidgets('OK key triggers onSelect', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      _host(
        TvFocusable(
          autofocus: true,
          onSelect: () => selected++,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(selected, 2);
  });

  testWidgets('focused TvFocusable shows a ring, unfocused does not', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TvFocusable(
          onSelect: () {},
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_hasRing(tester), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    final element = tester.element(find.byType(TvFocusable));
    FocusScope.of(element).nextFocus();
    await tester.pumpAndSettle();
    expect(_hasRing(tester), isTrue);
  });

  testWidgets('holding OK long-presses, a short press selects', (tester) async {
    var selected = 0;
    var longPressed = 0;
    await tester.pumpWidget(
      _host(
        TvFocusable(
          autofocus: true,
          onSelect: () => selected++,
          onLongPress: () => longPressed++,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    expect(selected, 0, reason: 'a press with a long-press action waits');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    expect((selected, longPressed), (0, 1));

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect((selected, longPressed), (1, 1));
  });

  testWidgets('a rebuilt TvFocusable shows the ring of its focused node', (
    tester,
  ) async {
    final node = FocusNode();
    Widget build(String key) => _host(
      TvFocusable(
        key: ValueKey(key),
        focusNode: node,
        onSelect: () {},
        child: const SizedBox(width: 100, height: 100),
      ),
    );
    await tester.pumpWidget(build('a'));
    node.requestFocus();
    await tester.pumpAndSettle();
    await tester.pumpWidget(build('b'));
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(node.hasFocus, isTrue);
    expect(_hasRing(tester), isTrue);
  });

  testWidgets('an arrow on a page with nothing focused focuses a control', (
    tester,
  ) async {
    final button = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TvFocusRescue(child: child!),
        home: Scaffold(
          body: TextButton(
            focusNode: button,
            onPressed: () {},
            child: const Text('ok'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(button.hasPrimaryFocus, isTrue);
  });

  testWidgets('left from a nested scope reaches the control beside it', (
    tester,
  ) async {
    final rail = FocusNode();
    final pane = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TvFocusRescue(child: child!),
        home: Scaffold(
          body: Row(
            children: [
              TextButton(
                focusNode: rail,
                onPressed: () {},
                child: const Text('rail'),
              ),
              // Like the settings pane: its own navigator, so its own scope.
              FocusScope(
                child: TextButton(
                  focusNode: pane,
                  autofocus: true,
                  onPressed: () {},
                  child: const Text('pane'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(pane.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(rail.hasPrimaryFocus, isTrue);
  });

  testWidgets('arrow right moves focus to the next card in a row', (
    tester,
  ) async {
    final nodes = {
      for (final k in ['a', 'b', 'c']) k: FocusNode(),
    };
    await tester.pumpWidget(
      _host(
        TvRow<String>(
          title: 'row',
          items: const ['a', 'b', 'c'],
          itemExtent: 120,
          height: 120,
          itemBuilder: (context, item, index) => TvFocusable(
            focusNode: nodes[item],
            autofocus: index == 0,
            onSelect: () {},
            child: Text(item),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(nodes['a']!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(nodes['b']!.hasFocus, isTrue);
  });

  testWidgets('a row shows only whole cards, never a cut-off one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 530,
          child: TvRow<int>(
            title: 'row',
            items: List.generate(10, (i) => i),
            itemExtent: 120,
            height: 120,
            itemBuilder: (context, item, index) => Text('$item'),
          ),
        ),
      ),
    );
    // 530 wide minus the 10 left inset fits 4 cards of 120; the 5th would be
    // cut. The row ends where the 5th card would start.
    expect(tester.getSize(find.byType(ListView)).width, 4 * 120 + 10);
  });

  testWidgets('up from a card reaches the button beside the row title', (
    tester,
  ) async {
    final button = FocusNode();
    await tester.pumpWidget(
      _host(
        TvRow<String>(
          title: 'row',
          items: const ['a', 'b'],
          itemExtent: 120,
          height: 120,
          trailing: TvButton(label: '分类', focusNode: button, onSelect: () {}),
          itemBuilder: (context, item, index) => TvFocusable(
            autofocus: index == 0,
            onSelect: () {},
            child: Text(item),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(button.hasFocus, isTrue);
  });

  testWidgets('removing the focused item moves focus to a sibling', (
    tester,
  ) async {
    final nodes = {
      for (final k in ['a', 'b', 'c']) k: FocusNode(),
    };
    late StateSetter setItems;
    var items = ['a', 'b', 'c'];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            setItems = setState;
            return TvRow<String>(
              title: 'row',
              items: items,
              itemExtent: 120,
              height: 120,
              itemBuilder: (context, item, index) => TvFocusable(
                focusNode: nodes[item],
                autofocus: index == 0,
                onSelect: () {},
                child: Text(item),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(nodes['b']!.hasFocus, isTrue);

    setItems(() => items = ['a', 'c']);
    await tester.pump();
    await tester.pump();
    expect(nodes['c']!.hasFocus, isTrue);
  });
}
