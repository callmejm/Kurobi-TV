import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';

/// Installs and updates rules from the rules repository, D-pad only.
class TvRulesPage extends StatefulWidget {
  const TvRulesPage({super.key, required this.controller});

  final PluginsController controller;

  @override
  State<TvRulesPage> createState() => _TvRulesPageState();
}

class _TvRulesPageState extends State<TvRulesPage> {
  bool _loading = true;
  bool _failed = false;
  final Map<String, String> _results = {};
  final Set<String> _busy = {};

  PluginsController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await _c.ensurePluginCatalog();
    } catch (error) {
      KazumiLogger().w('TvRulesPage: failed to load catalog', error: error);
      _failed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _install(String name) async {
    if (!_busy.add(name)) return;
    setState(() => _results[name] = '处理中…');
    String text;
    try {
      text = switch (await _c.tryUpdatePluginByName(name)) {
        PluginUpdateResult.updated => '完成',
        PluginUpdateResult.notNewer => '已是最新',
        PluginUpdateResult.requiresNewerClient => '需要更新 Kazumi',
        PluginUpdateResult.failed => '失败，按确认键重试',
      };
    } catch (_) {
      text = '失败，按确认键重试';
    }
    _busy.remove(name);
    if (mounted) setState(() => _results[name] = text);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed && _c.pluginHTTPList.isEmpty) {
      return TvMessage(text: '规则列表加载失败', actionLabel: '重试', onAction: _load);
    }
    final scheme = Theme.of(context).colorScheme;
    return Observer(
      builder: (_) {
        final items = _c.pluginHTTPList.toList();
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final status = _c.pluginStatus(item);
            final label = switch (status) {
              PluginCatalogItemStatus.install => '安装',
              PluginCatalogItemStatus.update => '更新',
              PluginCatalogItemStatus.installed => '已安装',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TvFocusable(
                autofocus: index == 0,
                onSelect: () => _install(item.name),
                child: ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name}  v${item.version}  ${item.author}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(_results[item.name] ?? label),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
