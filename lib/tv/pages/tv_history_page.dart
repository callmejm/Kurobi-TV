import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';

class TvHistoryPage extends StatefulWidget {
  const TvHistoryPage({super.key, required this.controller});

  final HistoryController controller;

  @override
  State<TvHistoryPage> createState() => _TvHistoryPageState();
}

class _TvHistoryPageState extends State<TvHistoryPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final items = widget.controller.histories.toList()
          ..sort((a, b) => b.lastWatchTime.compareTo(a.lastWatchTime));
        if (items.isEmpty) return const TvMessage(text: '还没有观看记录');
        return ListView(
          children: [
            TvRow<History>(
              title: '继续观看',
              items: items,
              itemBuilder: (context, item, index) => tvBangumiCard(
                context,
                item.bangumiItem,
                autofocus: index == 0,
                subtitle: item.lastWatchEpisodeName,
              ),
            ),
          ],
        );
      },
    );
  }
}
