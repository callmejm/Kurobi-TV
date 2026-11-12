import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/player/tv_player_overlay.dart';

void main() {
  test('episode labels fall back to 第 N 集 for missing or blank names', () {
    expect(tvEpisodeLabels(['01', '', '03'], 4), [
      '01',
      '第 2 集',
      '03',
      '第 4 集',
    ]);
  });

  testWidgets(
    'episode list focuses the playing episode even when another node holds focus',
    (tester) async {
      late StateSetter setOpen;
      var open = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              autofocus: true,
              child: StatefulBuilder(
                builder: (context, setState) {
                  setOpen = setState;
                  return open
                      ? TvEpisodeList(
                          labels: List.generate(40, (i) => '第${i + 1}集'),
                          selectedIndex: 25,
                          onSelect: (_) {},
                        )
                      : const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      setOpen(() => open = true);
      await tester.pump();
      await tester.pump();

      final primary = FocusManager.instance.primaryFocus!;
      expect(
        find.descendant(
          of: find.byElementPredicate((e) => e == primary.context),
          matching: find.text('第26集'),
        ),
        findsOneWidget,
      );
    },
  );
}
