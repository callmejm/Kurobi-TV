import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/tv/tv_nsfw.dart';
import 'package:kazumi/tv/tv_theme.dart';
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
    return Padding(
      padding: TvTokens.pagePadding,
      child: Observer(
        builder: (_) {
          final all = tvHideNsfw(
            widget.controller.collectibles,
            (c) => c.bangumiItem,
          );
          final groups = <(CollectType, List<CollectedBangumi>)>[
            for (final type in _shownTypes)
              (
                type,
                all.where((c) => c.type == type.value).toList()
                  ..sort((a, b) => b.time.compareTo(a.time)),
              ),
          ].where((group) => group.$2.isNotEmpty).toList();
          if (groups.isEmpty) return const TvMessage(text: '还没有收藏');
          return ListView(
            padding: const EdgeInsets.only(top: 12),
            children: [
              for (var row = 0; row < groups.length; row++)
                TvRow<CollectedBangumi>(
                  title: '${groups[row].$1.label}  ${groups[row].$2.length}',
                  items: groups[row].$2,
                  itemBuilder: (context, item, index) => tvBangumiCard(
                    context,
                    item.bangumiItem,
                    autofocus: row == 0 && index == 0,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
