import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/tv/tv_routes.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_source_picker.dart';

/// Anime detail: cover, summary, "watch" (opens the source picker) and a
/// collect button that cycles through the collect types.
class TvInfoPage extends StatefulWidget {
  const TvInfoPage({
    super.key,
    required this.bangumiItem,
    required this.infoController,
    required this.pluginsController,
    required this.collectController,
  });

  final BangumiItem bangumiItem;
  final InfoController infoController;
  final PluginsController pluginsController;
  final CollectController collectController;

  @override
  State<TvInfoPage> createState() => _TvInfoPageState();
}

class _TvInfoPageState extends State<TvInfoPage> {
  InfoController get _info => widget.infoController;

  @override
  void initState() {
    super.initState();
    _info.bangumiItem = widget.bangumiItem;
    _info.pluginSearchResponseList.clear();
    if (widget.bangumiItem.summary.isEmpty) {
      _info.queryBangumiInfoByID(widget.bangumiItem.id).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  CollectType get _collectType => CollectType.fromValue(
    widget.collectController.getCollectType(_info.bangumiItem),
  );

  Future<void> _cycleCollect() async {
    final values = CollectType.values;
    final next = values[(_collectType.index + 1) % values.length];
    await widget.collectController.addCollect(
      _info.bangumiItem,
      type: next.value,
    );
    if (mounted) setState(() {});
  }

  void _openSources() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: TvSourcePicker(
          infoController: _info,
          pluginsController: widget.pluginsController,
          onOpenRules: () {
            Navigator.of(dialogContext).pop();
            context.navigate(TvRoutes.rules);
          },
          onPlay: (args) {
            Navigator.of(dialogContext).pop();
            context.pushNamed(TvRoutes.video, arguments: args);
          },
        ),
      ),
    );
  }

  Widget _button(
    String label,
    VoidCallback onSelect, {
    bool autofocus = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TvFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      child: ColoredBox(
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _info.bangumiItem;
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 27),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              height: 400,
              child: NetworkImgLayer(
                src: item.images['large'] ?? '',
                width: 280,
                height: 400,
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameCn.isEmpty ? item.name : item.nameCn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (item.airDate.isNotEmpty) item.airDate,
                      if (item.ratingScore > 0) '评分 ${item.ratingScore}',
                    ].join('  ·  '),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Text(
                      item.summary,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      _button('开始观看', _openSources, autofocus: true),
                      const SizedBox(width: 16),
                      _button(
                        _collectType == CollectType.none
                            ? '未追'
                            : _collectType.label,
                        _cycleCollect,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
