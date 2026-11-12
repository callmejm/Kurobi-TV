import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/tv/tv_nsfw.dart';
import 'package:kazumi/tv/tv_routes.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_backdrop.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_headline.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_source_picker.dart';

/// Anime detail: cover, summary, tags (each opens a tag search), "watch"
/// (opens the source picker) and a collect button that cycles through the
/// collect types.
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
        backgroundColor: TvTokens.background,
        child: TvSourcePicker(
          infoController: _info,
          pluginsController: widget.pluginsController,
          onOpenRules: () {
            Navigator.of(dialogContext).pop();
            context.navigate(TvRoutes.rules);
          },
          onPlay: (request) {
            Navigator.of(dialogContext).pop();
            context.pushNamed(TvRoutes.video, arguments: request);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _info.bangumiItem;
    final collected = _collectType != CollectType.none;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          TvBackdrop(imageUrl: item.images['large'] ?? ''),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvTokens.edgeH,
              TvTokens.edgeV + 40,
              TvTokens.edgeH,
              TvTokens.edgeV + 20,
            ),
            child: FractionallySizedBox(
              widthFactor: 0.56,
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvBangumiHeadline(item: item, titleLines: 2, summaryLines: 4),
                  const SizedBox(height: 16),
                  // Tags, like the phone detail page; OK searches the tag.
                  // One scrolling line, so long tag lists never push the
                  // buttons off screen.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    // Room for the focus scale inside the clip.
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        for (final tag in item.tags.where(
                          (t) => tvShowNsfw.value || !isNsfwTag(t.name),
                        )) ...[
                          TvButton(
                            label: '${tag.name} ${tag.count}',
                            onSelect: () => context.pushNamed(
                              TvRoutes.tagSearch,
                              arguments: tag.name,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      TvButton(
                        icon: Icons.play_arrow_rounded,
                        label: '开始观看',
                        selected: true,
                        autofocus: true,
                        onSelect: _openSources,
                      ),
                      const SizedBox(width: 12),
                      TvButton(
                        icon: collected
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: collected ? _collectType.label : '追番',
                        onSelect: _cycleCollect,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
