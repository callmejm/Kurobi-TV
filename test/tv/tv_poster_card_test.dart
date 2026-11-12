import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_poster_card.dart';

void main() {
  testWidgets('long title and subtitle fit the poster row slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTvTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: TvTokens.posterWidth,
              height: TvTokens.posterHeight + 72,
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
    );
    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(find.textContaining('关于我转生'));
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
  });
}
