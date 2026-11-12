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

/// Airing schedule: weekday pills (OK or a tap shows that day) over a grid.
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
  final _pills = List.generate(
    _weekdayLabels.length,
    (i) => FocusNode(debugLabel: 'weekday $i'),
  );

  @override
  void initState() {
    super.initState();
    if (_c.bangumiCalendar.isEmpty) _c.loadSeason(_c.selectedDate);
  }

  @override
  void dispose() {
    for (final node in _pills) {
      node.dispose();
    }
    super.dispose();
  }

  /// Shows day [i]; on the day already shown, moves into its shows. Focus
  /// alone does not switch days: a tap does not move focus, and arrowing
  /// into the row would switch to whichever day is nearest.
  void _selectDay(int i, int shown) {
    if (i != shown) {
      setState(() => _day = i);
      _pills[i].requestFocus();
    } else {
      _pills[i].focusInDirection(TraversalDirection.down);
    }
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
                            focusNode: _pills[i],
                            label: i == _today ? '今天' : _weekdayLabels[i],
                            autofocus: i == day,
                            selected: i == day,
                            onSelect: () => _selectDay(i, day),
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
