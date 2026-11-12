import 'package:flutter/material.dart';
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
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';

/// Full-screen source chooser: searches every rule for the anime, lists the
/// hits per rule, and hands the chosen one to [onPlay].
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
  final void Function(OnlineVideoPlaybackArgs args) onPlay;
  final VoidCallback onOpenRules;

  @override
  State<TvSourcePicker> createState() => _TvSourcePickerState();
}

class _TvSourcePickerState extends State<TvSourcePicker> {
  late final PluginSearchService _service;
  late final String _keyword;
  String? _notice;
  bool _opening = false;

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
    super.dispose();
  }

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
      widget.onPlay(
        OnlineVideoPlaybackArgs(
          bangumiItem: _info.bangumiItem,
          plugin: plugin,
          title: item.name,
          src: item.src,
          roads: roads,
        ),
      );
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

  Widget _row(String text, {VoidCallback? onSelect, bool autofocus = false}) {
    final scheme = Theme.of(context).colorScheme;
    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: onSelect == null
          ? label
          : TvFocusable(
              autofocus: autofocus,
              onSelect: onSelect,
              child: ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: SizedBox(width: double.infinity, child: label),
              ),
            ),
    );
  }

  List<Widget> _section(Plugin plugin, bool first) {
    final status = _info.pluginSearchStatus[plugin.name];
    final title = Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(plugin.name, style: Theme.of(context).textTheme.titleMedium),
    );
    switch (status) {
      case PluginSearchStatus.success:
        final results = _info.pluginSearchResponseList
            .where((r) => r.pluginName == plugin.name)
            .expand((r) => r.data)
            .toList();
        return [
          title,
          for (var i = 0; i < results.length; i++)
            _row(
              results[i].name,
              autofocus: first && i == 0,
              onSelect: () => _open(plugin, results[i]),
            ),
        ];
      case PluginSearchStatus.captcha:
        return [title, _row('需要在手机上完成验证')];
      case PluginSearchStatus.noResult:
        return [title, _row('无结果')];
      case PluginSearchStatus.error:
        return [
          title,
          _row(
            '检索失败，按确认键重试',
            autofocus: first,
            onSelect: () => _service.querySource(_keyword, plugin.name),
          ),
        ];
      case PluginSearchStatus.pending:
      case null:
        return [title, _row('搜索中…')];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 27),
      child: Observer(
        builder: (_) {
          final plugins = widget.pluginsController.pluginList.toList();
          if (plugins.isEmpty) {
            return TvMessage(
              text: '还没有规则',
              actionLabel: '去安装规则',
              onAction: widget.onOpenRules,
            );
          }
          return ListView(
            children: [
              Text('选择视频源', style: Theme.of(context).textTheme.headlineSmall),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_notice!),
                ),
              for (var i = 0; i < plugins.length; i++)
                ..._section(plugins[i], i == 0),
            ],
          );
        },
      ),
    );
  }
}
