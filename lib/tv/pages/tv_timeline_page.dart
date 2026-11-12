import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/timeline/timeline_controller.dart';
import 'package:kazumi/tv/tv_nsfw.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';
import 'package:kazumi/tv/widgets/tv_poster_grid.dart';

const _weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// Airing schedule: weekday pills (focusing one shows that day) over a grid.
class TvTimelinePage extends StatefulWidget {
  const TvTimelinePage({super.key, required this.controller});

  final TimelineController controller;

  @override
  State<TvTimelinePage> createState() => _TvTimelinePageState();
}

class _TvTimelinePageState extends State<TvTimelinePage> {
  TimelineController get _c => widget.controller;
  final int _today = DateTime.now().weekday - 1;
  late int _day = _today;

  @override
  void initState() {
    super.initState();
    if (_c.bangumiCalendar.isEmpty) _c.loadSeason(_c.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: TvTokens.pagePadding,
      child: Observer(
        builder: (_) {
          if (_c.bangumiCalendar.isEmpty) {
            if (_c.isTimeOut) {
              return TvMessage(
                text: '加载失败',
                actionLabel: '重试',
                onAction: () => _c.loadSeason(_c.selectedDate),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final day = _day.clamp(0, _c.bangumiCalendar.length - 1);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TvTokens.itemInset,
                  12,
                  0,
                  4,
                ),
                child: FocusTraversalGroup(
                  child: Row(
                    children: [
                      for (var i = 0; i < _weekdayLabels.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TvButton(
                            label: i == _today ? '今天' : _weekdayLabels[i],
                            autofocus: i == day,
                            selected: i == day,
                            onFocusChange: (focused) {
                              if (focused && _day != i) {
                                setState(() => _day = i);
                              }
                            },
                            // OK jumps into the day's shows.
                            onSelect: () => FocusManager.instance.primaryFocus
                                ?.focusInDirection(TraversalDirection.down),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TvPosterGrid<BangumiItem>(
                  // A new grid per day so its scroll starts at the top.
                  key: ValueKey(day),
                  items: tvHideNsfw(_c.bangumiCalendar[day], (item) => item),
                  itemBuilder: (context, item, index) =>
                      tvBangumiCard(context, item),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
