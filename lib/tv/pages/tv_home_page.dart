import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';

class TvHomePage extends StatefulWidget {
  const TvHomePage({super.key, required this.controller});

  final PopularController controller;

  @override
  State<TvHomePage> createState() => _TvHomePageState();
}

class _TvHomePageState extends State<TvHomePage> {
  PopularController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (_c.trendList.isEmpty) _c.queryBangumiByTrend();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (_c.trendList.isEmpty) {
          if (_c.isTimeOut) {
            return TvMessage(
              text: '加载失败',
              actionLabel: '重试',
              onAction: _c.queryBangumiByTrend,
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: [
            TvRow<BangumiItem>(
              title: '热门',
              items: _c.trendList.toList(),
              itemBuilder: (context, item, index) =>
                  tvBangumiCard(context, item, autofocus: index == 0),
              onIndexFocused: (index) {
                if (index >= _c.trendList.length - 5 && !_c.isLoadingMore) {
                  _c.queryBangumiByTrend();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
