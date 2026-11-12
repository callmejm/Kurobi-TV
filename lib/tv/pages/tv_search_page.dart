import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/pages/search/search_controller.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

class TvSearchPage extends StatefulWidget {
  const TvSearchPage({super.key, required this.controller});

  final SearchPageController controller;

  @override
  State<TvSearchPage> createState() => _TvSearchPageState();
}

class _TvSearchPageState extends State<TvSearchPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
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
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit(String input) {
    final query = input.trim();
    if (query.isEmpty) return;
    _text.text = query;
    _lastQuery = query;
    _c.searchBangumi(query, type: 'init');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _submit,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: '搜索番剧',
          ),
        ),
        const SizedBox(height: 12),
        Observer(
          builder: (_) => Wrap(
            spacing: 12,
            children: [
              for (final history in _c.searchHistories)
                TvFocusable(
                  onSelect: () => _submit(history.keyword),
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(history.keyword),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Observer(
            builder: (_) {
              if (_c.bangumiList.isEmpty) {
                return Center(
                  child: Text(
                    _c.isLoading
                        ? '搜索中…'
                        : _c.isTimeOut
                        ? '没有结果'
                        : '输入关键词后按确认键搜索',
                  ),
                );
              }
              final items = _c.bangumiList.toList();
              return GridView.builder(
                controller: _scroll,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 200 / 300,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    tvBangumiCard(context, items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
