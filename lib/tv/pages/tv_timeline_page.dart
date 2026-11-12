import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/timeline/timeline_controller.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';

const _weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

class TvTimelinePage extends StatefulWidget {
  const TvTimelinePage({super.key, required this.controller});

  final TimelineController controller;

  @override
  State<TvTimelinePage> createState() => _TvTimelinePageState();
}

class _TvTimelinePageState extends State<TvTimelinePage> {
  TimelineController get _c => widget.controller;
  int _day = DateTime.now().weekday - 1;

  @override
  void initState() {
    super.initState();
    if (_c.bangumiCalendar.isEmpty) _c.loadSeason(_c.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Observer(
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
        return ListView(
          children: [
            Row(
              children: [
                for (var i = 0; i < _weekdayLabels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 16),
                    child: TvFocusable(
                      autofocus: i == day,
                      onSelect: () => setState(() => _day = i),
                      child: ColoredBox(
                        color: i == day
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Text(_weekdayLabels[i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            TvRow<BangumiItem>(
              title: _weekdayLabels[day],
              items: _c.bangumiCalendar[day].toList(),
              itemBuilder: (context, item, index) =>
                  tvBangumiCard(context, item),
            ),
          ],
        );
      },
    );
  }
}
