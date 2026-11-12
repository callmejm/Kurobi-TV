import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_backdrop.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_headline.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';

/// Home: the focused show fills the top as backdrop and headline; below it
/// "continue watching" and trending rows.
class TvHomePage extends StatefulWidget {
  const TvHomePage({
    super.key,
    required this.controller,
    required this.historyController,
  });

  final PopularController controller;
  final HistoryController historyController;

  @override
  State<TvHomePage> createState() => _TvHomePageState();
}

class _TvHomePageState extends State<TvHomePage> {
  PopularController get _c => widget.controller;
  BangumiItem? _featured;
  Timer? _featureDelay;

  @override
  void initState() {
    super.initState();
    widget.historyController.init();
    if (_c.trendList.isEmpty) _c.queryBangumiByTrend();
  }

  @override
  void dispose() {
    _featureDelay?.cancel();
    super.dispose();
  }

  /// Waits for the D-pad to rest so fast scrolling does not decode a backdrop
  /// per key press.
  void _feature(BangumiItem item) {
    _featureDelay?.cancel();
    _featureDelay = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _featured?.id != item.id) {
        setState(() => _featured = item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final trends = _c.trendList.toList();
        if (trends.isEmpty) {
          if (_c.isTimeOut) {
            return TvMessage(
              text: '加载失败',
              actionLabel: '重试',
              onAction: _c.queryBangumiByTrend,
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final history = widget.historyController.histories.toList()
          ..sort((a, b) => b.lastWatchTime.compareTo(a.lastWatchTime));
        final featured = _featured ?? trends.first;
        return Stack(
          fit: StackFit.expand,
          children: [
            TvBackdrop(imageUrl: featured.images['large'] ?? ''),
            Padding(
              padding: TvTokens.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TvTokens.itemInset,
                      12,
                      0,
                      20,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.55,
                      child: TvBangumiHeadline(item: featured),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        if (history.isNotEmpty)
                          TvRow<History>(
                            title: '继续观看',
                            items: history.take(20).toList(),
                            itemBuilder: (context, item, index) =>
                                tvBangumiCard(
                                  context,
                                  item.bangumiItem,
                                  autofocus: index == 0,
                                  subtitle: item.lastWatchEpisodeName,
                                  onFocusChange: (focused) {
                                    if (focused) _feature(item.bangumiItem);
                                  },
                                ),
                          ),
                        TvRow<BangumiItem>(
                          title: '热门番剧',
                          items: trends,
                          itemBuilder: (context, item, index) => tvBangumiCard(
                            context,
                            item,
                            autofocus: history.isEmpty && index == 0,
                            onFocusChange: (focused) {
                              if (focused) _feature(item);
                            },
                          ),
                          onIndexFocused: (index) {
                            if (index >= _c.trendList.length - 5 &&
                                !_c.isLoadingMore) {
                              _c.queryBangumiByTrend();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
