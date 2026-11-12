import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';

const _shownTypes = [
  CollectType.watching,
  CollectType.planToWatch,
  CollectType.onHold,
  CollectType.watched,
  CollectType.abandoned,
];

class TvCollectPage extends StatefulWidget {
  const TvCollectPage({super.key, required this.controller});

  final CollectController controller;

  @override
  State<TvCollectPage> createState() => _TvCollectPageState();
}

class _TvCollectPageState extends State<TvCollectPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadCollectibles();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final all = widget.controller.collectibles.toList();
        final rows = <Widget>[];
        for (final type in _shownTypes) {
          final items = all.where((c) => c.type == type.value).toList()
            ..sort((a, b) => b.time.compareTo(a.time));
          if (items.isEmpty) continue;
          rows.add(
            TvRow<CollectedBangumi>(
              title: type.label,
              items: items,
              itemBuilder: (context, item, index) => tvBangumiCard(
                context,
                item.bangumiItem,
                autofocus: rows.isEmpty && index == 0,
              ),
            ),
          );
        }
        if (rows.isEmpty) return const TvMessage(text: '还没有收藏');
        return ListView(children: rows);
      },
    );
  }
}
