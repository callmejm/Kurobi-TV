import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/tv/tv_nsfw.dart';
import 'package:kazumi/tv/tv_routes.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_backdrop.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_headline.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_message.dart';
import 'package:kazumi/tv/widgets/tv_poster_grid.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';
import 'package:kazumi/utils/constants.dart';

/// Category name shown for a [PopularController.currentTag]; '' is trending.
String tvTagLabel(String tag) => tag.isEmpty ? '热门番剧' : tag;

/// Home: the focused show fills the top as backdrop and headline; below it
/// "continue watching" and the category row, which can switch to a grid.
class TvHomePage extends StatefulWidget {
  const TvHomePage({
    super.key,
    required this.controller,
    required this.historyController,
  });

  final PopularController controller;
  final HistoryController historyController;

  @override
  State<TvHomePage> createState() => _TvHomePageState();
}

class _TvHomePageState extends State<TvHomePage> {
  PopularController get _c => widget.controller;
  BangumiItem? _featured;
  Timer? _featureDelay;
  bool _grid = false;

  /// Shared by the row and grid headers, so focus can return to the button
  /// after the header is rebuilt for a new category or view.
  final _tagButton = FocusNode(debugLabel: 'category');
  final _gridToggle = FocusNode(debugLabel: 'grid toggle');

  @override
  void initState() {
    super.initState();
    widget.historyController.init();
    if (_c.trendList.isEmpty) _c.queryBangumiByTrend();
  }

  @override
  void dispose() {
    _featureDelay?.cancel();
    _tagButton.dispose();
    _gridToggle.dispose();
    super.dispose();
  }

  /// Waits for the D-pad to rest so fast scrolling does not decode a backdrop
  /// per key press.
  void _feature(BangumiItem item) {
    _featureDelay?.cancel();
    _featureDelay = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _featured?.id != item.id) {
        setState(() => _featured = item);
      }
    });
  }

  List<BangumiItem> get _items => tvHideNsfw(
    _c.currentTag.isEmpty ? _c.trendList : _c.bangumiList,
    (item) => item,
  );

  /// Loads the next page when focus nears the end of the list.
  void _onIndexFocused(int index) {
    if (index < _items.length - 6 || _c.isLoadingMore) return;
    _c.currentTag.isEmpty ? _c.queryBangumiByTrend() : _c.queryBangumiByTag();
  }

  /// Same switch as the phone popular page.
  Future<void> _selectTag(String tag) async {
    if (tag == _c.currentTag) return;
    _c.setCurrentTag(tag);
    if (tag.isEmpty) {
      _c.clearBangumiList();
      if (_c.trendList.isEmpty) await _c.queryBangumiByTrend();
    } else {
      await _c.queryBangumiByTag(type: 'init');
    }
  }

  void _pickTag() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: TvTokens.surfaceHigh,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('选择分类', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              SizedBox(
                width: 560,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final tag in ['', ...defaultAnimeTags])
                      TvButton(
                        label: tvTagLabel(tag),
                        selected: tag == _c.currentTag,
                        autofocus: tag == _c.currentTag,
                        onSelect: () {
                          Navigator.of(dialogContext).pop();
                          _selectTag(tag);
                          _focusLater(_tagButton);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Small menu for a "continue watching" card: open it or remove it.
  void _historyMenu(History history) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: TvTokens.surfaceHigh,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tvBangumiTitle(history.bangumiItem),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TvButton(
                    icon: Icons.info_outline_rounded,
                    label: '查看详情',
                    autofocus: true,
                    onSelect: () {
                      Navigator.of(dialogContext).pop();
                      context.pushNamed(
                        TvRoutes.info,
                        arguments: history.bangumiItem,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  TvButton(
                    icon: Icons.delete_outline_rounded,
                    label: '删除记录',
                    onSelect: () {
                      Navigator.of(dialogContext).pop();
                      widget.historyController.deleteHistory(history);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _focusLater(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  void _toggleGrid() {
    setState(() => _grid = !_grid);
    _focusLater(_gridToggle);
  }

  Widget _actions() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      TvButton(
        focusNode: _tagButton,
        icon: Icons.category_rounded,
        label: '分类',
        onSelect: _pickTag,
      ),
      const SizedBox(width: 12),
      TvButton(
        focusNode: _gridToggle,
        icon: _grid ? Icons.view_carousel_rounded : Icons.grid_view_rounded,
        label: _grid ? '横排' : '网格',
        onSelect: _toggleGrid,
      ),
    ],
  );

  Widget _card(BangumiItem item, {bool autofocus = false}) => tvBangumiCard(
    context,
    item,
    autofocus: autofocus,
    onFocusChange: (focused) {
      if (focused) _feature(item);
    },
  );

  Widget _gridView(List<BangumiItem> items) {
    return Padding(
      padding: TvTokens.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(TvTokens.itemInset, 12, 0, 4),
            child: Row(
              children: [
                Text(
                  tvTagLabel(_c.currentTag),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 16),
                _actions(),
              ],
            ),
          ),
          Expanded(
            child: TvPosterGrid<BangumiItem>(
              // A new grid per category so its scroll starts at the top.
              key: ValueKey(_c.currentTag),
              items: items,
              itemBuilder: (context, item, index) => Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: (focused) {
                  if (focused) _onIndexFocused(index);
                },
                child: _card(item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final trends = _c.trendList.toList();
        if (trends.isEmpty && _c.currentTag.isEmpty) {
          if (_c.isTimeOut) {
            return TvMessage(
              text: '加载失败',
              actionLabel: '重试',
              onAction: _c.queryBangumiByTrend,
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final items = _items;
        if (_grid) return _gridView(items);
        final history = tvHideNsfw(
          widget.historyController.histories,
          (h) => h.bangumiItem,
        )..sort((a, b) => b.lastWatchTime.compareTo(a.lastWatchTime));
        final featured =
            _featured ??
            (items.isNotEmpty ? items.first : null) ??
            trends.firstOrNull;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (featured != null)
              TvBackdrop(imageUrl: featured.images['large'] ?? ''),
            Padding(
              padding: TvTokens.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TvTokens.itemInset,
                      12,
                      0,
                      20,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.55,
                      child: featured == null
                          ? const SizedBox.shrink()
                          : TvBangumiHeadline(item: featured),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        if (history.isNotEmpty)
                          TvRow<History>(
                            title: '继续观看',
                            items: history.take(20).toList(),
                            itemBuilder: (context, item, index) =>
                                tvBangumiCard(
                                  context,
                                  item.bangumiItem,
                                  autofocus: index == 0,
                                  subtitle: item.lastWatchEpisodeName,
                                  onLongPress: () => _historyMenu(item),
                                  onFocusChange: (focused) {
                                    if (focused) _feature(item.bangumiItem);
                                  },
                                ),
                          ),
                        TvRow<BangumiItem>(
                          // A new row per category so its scroll starts at 0.
                          key: ValueKey(_c.currentTag),
                          title: tvTagLabel(_c.currentTag),
                          trailing: _actions(),
                          items: items,
                          itemBuilder: (context, item, index) => _card(
                            item,
                            autofocus: history.isEmpty && index == 0,
                          ),
                          onIndexFocused: _onIndexFocused,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
