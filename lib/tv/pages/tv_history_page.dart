import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/tv/tv_nsfw.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';
import 'package:kazumi/tv/widgets/tv_poster_grid.dart';

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
    return Padding(
      padding: TvTokens.pagePadding,
      child: Observer(
        builder: (_) {
          final items = tvHideNsfw(
            widget.controller.histories,
            (h) => h.bangumiItem,
          )..sort((a, b) => b.lastWatchTime.compareTo(a.lastWatchTime));
          if (items.isEmpty) return const TvMessage(text: '还没有观看记录');
          return TvPosterGrid<History>(
            items: items,
            itemBuilder: (context, item, index) => tvBangumiCard(
              context,
              item.bangumiItem,
              autofocus: index == 0,
              subtitle: item.lastWatchEpisodeName,
            ),
          );
        },
      ),
    );
  }
}
