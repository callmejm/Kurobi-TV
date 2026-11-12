import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/search/plugin_search_module.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/pages/video/video_playback_args.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/plugin/plugin_search_service.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart'
    show RuleCancelToken;
import 'package:kazumi/tv/player/tv_player_overlay.dart' show tvEpisodeLabels;
import 'package:kazumi/tv/player/tv_player_page.dart' show TvPlaybackRequest;
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';

/// Full-screen source chooser: searches every rule for the anime, lists the
/// hits per rule, then the chosen hit's episodes, and hands the chosen
/// episode to [onPlay]. Back from the episodes returns to the hits.
class TvSourcePicker extends StatefulWidget {
  const TvSourcePicker({
    super.key,
    required this.infoController,
    required this.pluginsController,
    required this.onPlay,
    required this.onOpenRules,
  });

  final InfoController infoController;
  final PluginsController pluginsController;
  final void Function(TvPlaybackRequest request) onPlay;
  final VoidCallback onOpenRules;

  @override
  State<TvSourcePicker> createState() => _TvSourcePickerState();
}

class _TvSourcePickerState extends State<TvSourcePicker> {
  late final PluginSearchService _service;
  late final String _keyword;
  String? _notice;
  bool _opening = false;

  /// The hit whose episodes are listed; null while choosing a hit.
  OnlineVideoPlaybackArgs? _chosen;

  InfoController get _info => widget.infoController;

  @override
  void initState() {
    super.initState();
    final item = _info.bangumiItem;
    _keyword = item.nameCn.isEmpty ? item.name : item.nameCn;
    _service = PluginSearchService(
      infoController: _info,
      pluginsController: widget.pluginsController,
    );
    _service.queryAllSource(_keyword);
  }

  @override
  void dispose() {
    _service.cancel();
    _area.dispose();
    super.dispose();
  }

  final FocusNode _area = FocusNode(
    debugLabel: 'source picker',
    skipTraversal: true,
  );

  /// Set by the first key press; until then focus follows the top tile.
  bool _moved = false;

  /// Results stream in and re-sort, so the tile that was first to appear can
  /// end up off screen. Until the user moves, keep focus on the top-left tile;
  /// after that only rescue focus if it was lost.
  void _keepFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (_moved && _area.hasFocus)) return;
      final tiles = _area.traversalDescendants;
      if (tiles.isEmpty) return;
      final top = tiles.reduce((a, b) {
        final dy = a.rect.top - b.rect.top;
        if (dy.abs() > 1) return dy < 0 ? a : b;
        return a.rect.left <= b.rect.left ? a : b;
      });
      if (!top.hasPrimaryFocus) top.requestFocus();
    });
  }

  /// Results first, then retry tiles, then sections with nothing to select.
  int _rank(Plugin plugin) => switch (_info.pluginSearchStatus[plugin.name]) {
    PluginSearchStatus.success => 0,
    PluginSearchStatus.error => 1,
    PluginSearchStatus.pending || null => 2,
    _ => 3,
  };

  Future<void> _open(Plugin plugin, SearchItem item) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _notice = '正在获取播放列表…';
    });
    try {
      final roads = await plugin.queryChapterRoads(
        item.src,
        cancelToken: RuleCancelToken(),
      );
      if (!mounted) return;
      if (roads.isEmpty) throw ChapterErrorException(plugin.name);
      setState(() {
        _notice = null;
        _chosen = OnlineVideoPlaybackArgs(
          bangumiItem: _info.bangumiItem,
          plugin: plugin,
          title: item.name,
          src: item.src,
          roads: roads,
        );
      });
    } catch (error) {
      KazumiLogger().w(
        'TvSourcePicker: failed to query playlist',
        error: error,
      );
      if (mounted) setState(() => _notice = '未能获取播放列表，请重试或选择其他结果');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  /// One result tile: white with dark text when focused.
  Widget _tile(String text, {required VoidCallback onSelect}) {
    final style = Theme.of(context).textTheme.bodyLarge!;
    return TvFocusable(
      onSelect: onSelect,
      ring: false,
      scale: 1.05,
      builder: (context, focused) => AnimatedContainer(
        duration: TvTokens.focusDuration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.centerLeft,
        color: focused ? TvTokens.focus : TvTokens.surfaceHigh,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(color: focused ? Colors.black : TvTokens.text),
        ),
      ),
    );
  }

  /// One row per road (playback line) of the chosen hit.
  List<Widget> _episodeRows(OnlineVideoPlaybackArgs chosen) => [
    for (var r = 0; r < chosen.roads.length; r++)
      if (chosen.roads[r].data.isNotEmpty)
        KeyedSubtree(
          key: ValueKey('road $r'),
          child: TvRow<String>(
            title:
                '${chosen.roads[r].name.isEmpty ? '线路 ${r + 1}' : chosen.roads[r].name}'
                '  ·  ${chosen.roads[r].data.length} 集',
            items: tvEpisodeLabels(
              chosen.roads[r].identifier,
              chosen.roads[r].data.length,
            ),
            itemExtent: 236,
            height: 88,
            itemBuilder: (context, label, index) => _tile(
              label,
              onSelect: () => widget.onPlay(
                TvPlaybackRequest(chosen, episode: index + 1, road: r),
              ),
            ),
          ),
        ),
  ];

  Widget _section(Plugin plugin) {
    final status = _info.pluginSearchStatus[plugin.name];
    final text = Theme.of(context).textTheme;
    Widget note(String message) => Padding(
      padding: const EdgeInsets.fromLTRB(TvTokens.itemInset, 6, 0, 22),
      child: Text(
        '${plugin.name}  ·  $message',
        style: text.titleMedium!.copyWith(color: TvTokens.textMuted),
      ),
    );
    switch (status) {
      case PluginSearchStatus.success:
        final results = _info.pluginSearchResponseList
            .where((r) => r.pluginName == plugin.name)
            .expand((r) => r.data)
            .toList();
        return TvRow<SearchItem>(
          title: '${plugin.name}  ·  ${results.length} 个结果',
          items: results,
          itemExtent: 236,
          height: 88,
          itemBuilder: (context, item, index) =>
              _tile(item.name, onSelect: () => _open(plugin, item)),
        );
      case PluginSearchStatus.captcha:
        return note('需要在手机上完成验证');
      case PluginSearchStatus.noResult:
        return note('无结果');
      case PluginSearchStatus.error:
        return TvRow<String>(
          title: '${plugin.name}  ·  检索失败',
          items: const ['重试'],
          itemExtent: 236,
          height: 88,
          itemBuilder: (context, item, index) => _tile(
            '按确认键重试',
            onSelect: () => _service.querySource(_keyword, plugin.name),
          ),
        );
      case PluginSearchStatus.pending:
      case null:
        return note('搜索中…');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TvTokens.edgeH - TvTokens.itemInset,
        TvTokens.edgeV,
        TvTokens.edgeH - TvTokens.itemInset,
        0,
      ),
      child: Observer(
        builder: (_) {
          final installed = widget.pluginsController.pluginList.toList();
          final plugins = [...installed]
            ..sort((a, b) {
              final byRank = _rank(a).compareTo(_rank(b));
              return byRank != 0
                  ? byRank
                  : installed.indexOf(a).compareTo(installed.indexOf(b));
            });
          if (plugins.isEmpty) {
            return TvMessage(
              text: '还没有规则',
              actionLabel: '去安装规则',
              onAction: widget.onOpenRules,
            );
          }
          _keepFocus();
          final chosen = _chosen;
          return PopScope(
            canPop: chosen == null,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) setState(() => _chosen = null);
            },
            child: Focus(
              focusNode: _area,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent) _moved = true;
                return KeyEventResult.ignored;
              },
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TvTokens.itemInset,
                      0,
                      0,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chosen == null ? '选择播放源' : '选择剧集',
                          style: text.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _notice ??
                              (chosen == null
                                  ? '在已安装的规则中搜索「$_keyword」'
                                  : '${chosen.plugin.name}  ·  ${chosen.title}'
                                        '    按返回键重新选择播放源'),
                          style: text.bodyMedium!.copyWith(
                            color: TvTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (chosen != null)
                    ..._episodeRows(chosen)
                  else
                    for (final plugin in plugins)
                      KeyedSubtree(
                        key: ValueKey(plugin.name),
                        child: _section(plugin),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
