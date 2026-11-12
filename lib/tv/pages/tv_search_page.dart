import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/search/search_controller.dart';
import 'package:kazumi/tv/tv_nsfw.dart';
import 'package:kazumi/utils/search_parser.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_poster_grid.dart';

/// Search: a field that opens the system keyboard only on OK (so browsing
/// past the tab never pops it), recent searches, and a result grid.
class TvSearchPage extends StatefulWidget {
  const TvSearchPage({
    super.key,
    required this.controller,
    this.initialQuery = '',
  });

  final SearchPageController controller;

  /// Searched on open, e.g. `tag:异世界` from a detail page tag.
  final String initialQuery;

  @override
  State<TvSearchPage> createState() => _TvSearchPageState();
}

class _TvSearchPageState extends State<TvSearchPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _fieldNode = FocusNode(debugLabel: 'search field');
  final _editNode = FocusNode(debugLabel: 'search input');
  final _sortNode = FocusNode(debugLabel: 'sort');
  bool _editing = false;
  String _lastQuery = '';

  SearchPageController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.loadSearchHistories();
    _scroll.addListener(() {
      if (_lastQuery.isNotEmpty &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _c.searchBangumi(_lastQuery);
      }
    });
    _editNode.addListener(() {
      if (!_editNode.hasFocus && _editing) _stopEditing();
    });
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submit(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    _fieldNode.dispose();
    _editNode.dispose();
    _sortNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editNode.requestFocus();
    });
  }

  void _stopEditing() {
    // A hidden-but-attached IME keeps its Back callback and swallows the
    // next Back press, so detach it explicitly.
    setState(() => _editing = false);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    _editNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fieldNode.requestFocus();
    });
  }

  Future<void> _submit(String input) async {
    final query = input.trim();
    if (_editing) _stopEditing();
    if (query.isEmpty) return;
    setState(() {
      _text.text = query;
      _lastQuery = query;
    });
    await _c.searchBangumi(query, type: 'init');
  }

  static const _sortLabels = {
    'heat': '热度',
    'rank': '排名',
    'score': '评分',
    'match': '匹配',
  };

  /// Sort choices of the phone search, applied by re-searching the query
  /// with its `sort:` token, as the phone page does.
  void _pickSort(SearchFilterState filters) {
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
              for (final MapEntry(key: sort, value: label)
                  in _sortLabels.entries) ...[
                TvButton(
                  label: '按$label排序',
                  selected: sort == filters.sort,
                  autofocus: sort == filters.sort,
                  onSelect: () {
                    Navigator.of(dialogContext).pop();
                    if (sort == filters.sort) return;
                    // The header hides while loading, so focus returns after.
                    _submit(
                      SearchParser.fromFilterState(
                        filters.copyWith(sort: sort),
                      ),
                    ).then((_) {
                      if (mounted) _sortNode.requestFocus();
                    });
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (_editing) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          color: TvTokens.surfaceHigh,
          borderRadius: TvTokens.pillRadius,
        ),
        child: TextField(
          controller: _text,
          focusNode: _editNode,
          textInputAction: TextInputAction.search,
          onSubmitted: _submit,
          style: text.bodyLarge,
          decoration: const InputDecoration(
            border: InputBorder.none,
            icon: Icon(Icons.search_rounded, color: TvTokens.textMuted),
            hintText: '输入番剧名称',
          ),
        ),
      );
    }
    return TvFocusable(
      focusNode: _fieldNode,
      autofocus: true,
      onSelect: _startEditing,
      ring: false,
      scale: 1.02,
      borderRadius: TvTokens.pillRadius,
      builder: (context, focused) => AnimatedContainer(
        duration: TvTokens.focusDuration,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        color: focused ? TvTokens.focus : TvTokens.surface,
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: focused ? Colors.black : TvTokens.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _text.text.isEmpty ? '搜索番剧（按确认键输入）' : _text.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge!.copyWith(
                  color: focused ? Colors.black : TvTokens.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodyLarge!.copyWith(color: TvTokens.textMuted);
    return Padding(
      padding: TvTokens.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvTokens.itemInset,
              12,
              TvTokens.itemInset,
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 0.6,
              child: _field(context),
            ),
          ),
          Observer(
            builder: (_) {
              final histories = _c.searchHistories.take(8).toList();
              if (histories.isEmpty) return const SizedBox(height: 8);
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  TvTokens.itemInset,
                  14,
                  0,
                  4,
                ),
                child: FocusTraversalGroup(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final history in histories)
                        TvButton(
                          icon: Icons.history_rounded,
                          label: history.keyword,
                          onSelect: () => _submit(history.keyword),
                        ),
                      TvButton(
                        icon: Icons.delete_sweep_rounded,
                        label: '清空记录',
                        onSelect: _c.clearSearchHistory,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Observer(
              builder: (_) {
                final results = tvHideNsfw(_c.bangumiList, (item) => item);
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      _c.isLoading
                          ? '搜索中…'
                          : (_lastQuery.isNotEmpty && _c.isTimeOut
                                ? '没有找到「$_lastQuery」'
                                : '用遥控器输入关键词搜索'),
                      style: muted,
                    ),
                  );
                }
                final filters = SearchParser(_lastQuery).toFilterState();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Like the phone results header: count and sort.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TvTokens.itemInset,
                        10,
                        0,
                        4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '搜索结果',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(width: 12),
                          Text('${results.length} 部番剧', style: muted),
                          const SizedBox(width: 16),
                          if (!filters.isIdSearch)
                            TvButton(
                              focusNode: _sortNode,
                              icon: Icons.sort_rounded,
                              label: _sortLabels[filters.sort] ?? '热度',
                              onSelect: () => _pickSort(filters),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TvPosterGrid<BangumiItem>(
                        controller: _scroll,
                        items: results,
                        itemBuilder: (context, item, index) =>
                            tvBangumiCard(context, item),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
