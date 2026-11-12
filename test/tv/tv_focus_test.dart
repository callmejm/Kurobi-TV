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
