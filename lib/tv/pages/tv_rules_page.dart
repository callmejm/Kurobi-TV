import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/tv/tv_theme.dart';
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
        PluginUpdateResult.requiresNewerClient => '需要更新应用',
        PluginUpdateResult.failed => '失败，按确认键重试',
      };
    } catch (_) {
      text = '失败，按确认键重试';
    }
    _busy.remove(name);
    if (mounted) setState(() => _results[name] = text);
  }

  Widget _status(String label, bool installed, bool focused) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: focused
            ? Colors.black.withValues(alpha: 0.08)
            : (installed ? Colors.transparent : accent.withValues(alpha: 0.2)),
        borderRadius: TvTokens.pillRadius,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
          color: focused
              ? Colors.black
              : (installed ? TvTokens.textMuted : accent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_failed && _c.pluginHTTPList.isEmpty) {
      body = TvMessage(text: '规则列表加载失败', actionLabel: '重试', onAction: _load);
    } else {
      final text = Theme.of(context).textTheme;
      body = Observer(
        builder: (_) {
          final items = _c.pluginHTTPList.toList();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              TvTokens.itemInset,
              16,
              TvTokens.itemInset,
              24,
            ),
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
                padding: const EdgeInsets.only(bottom: 10),
                child: TvFocusable(
                  autofocus: index == 0,
                  onSelect: () => _install(item.name),
                  ring: false,
                  scale: 1.02,
                  builder: (context, focused) => AnimatedContainer(
                    duration: TvTokens.focusDuration,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    color: focused ? TvTokens.focus : TvTokens.surface,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium!.copyWith(
                                  color: focused ? Colors.black : TvTokens.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  'v${item.version}',
                                  if (item.author.isNotEmpty) item.author,
                                ].join('  ·  '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall!.copyWith(
                                  color: focused
                                      ? Colors.black54
                                      : TvTokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _status(
                          _results[item.name] ?? label,
                          status == PluginCatalogItemStatus.installed,
                          focused,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }
    return Padding(
      padding: TvTokens.pagePadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 260,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TvTokens.itemInset, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('规则', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  Text(
                    '规则决定从哪些站点查找视频。安装后在番剧详情页选择「开始观看」即可使用。',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: TvTokens.textMuted),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
