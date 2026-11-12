import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/widgets/tv_poster_card.dart';

void main() {
  testWidgets('long title and subtitle do not overflow at text scale 1.3', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 300,
                child: TvPosterCard(
                  title: '关于我转生变成史莱姆这档事 第三季 超长标题超长标题超长标题超长标题',
                  subtitle: '第 12 集 超长副标题超长副标题超长副标题',
                  cover: const ColoredBox(color: Colors.grey),
                  onSelect: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(find.textContaining('关于我转生'));
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
  });
}
