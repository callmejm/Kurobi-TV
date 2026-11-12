import 'package:flutter/material.dart';
import 'package:kazumi/tv/tv_theme.dart';

/// Titled horizontal row of D-pad focusable items.
///
/// The focused item is scrolled to the row's first slot, so focus sits in a
/// fixed place while the row moves under it. Moving up or down between rows
/// then lands on the other row's first visible item, which is the item that
/// was focused there last.
///
/// If the focused item disappears (list reloaded or shortened), focus moves to
/// the item now at the same position, or the last one, so it is never lost.
class TvRow<T> extends StatefulWidget {
  const TvRow({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.itemExtent = TvTokens.posterWidth + TvTokens.posterGap,
    this.height = TvTokens.posterHeight + 88,
    this.onIndexFocused,
    this.initialIndex = 0,
    this.trailing,
  });

  /// Shown after the title, e.g. buttons acting on the row.
  final Widget? trailing;

  /// Item scrolled into view when the row first builds (e.g. the playing episode).
  final int initialIndex;

  /// Called with the item index whenever an item gains focus (for paging).
  final void Function(int index)? onIndexFocused;

  final String title;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double itemExtent;
  final double height;

  @override
  State<TvRow<T>> createState() => _TvRowState<T>();
}

class _TvRowState<T> extends State<TvRow<T>> {
  // Room for the focus scale and ring at the row's edges.
  static const _inset = EdgeInsets.symmetric(horizontal: 10, vertical: 12);

  final List<FocusNode> _nodes = [];
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.initialIndex * widget.itemExtent,
  );
  int _lastIndex = 0;

  FocusNode _nodeFor(int index) {
    while (_nodes.length <= index) {
      _nodes.add(FocusNode(skipTraversal: true, canRequestFocus: false));
    }
    return _nodes[index];
  }

  void _onItemFocused(int index) {
    _lastIndex = index;
    widget.onIndexFocused?.call(index);
    // After TvFocusable's ensureVisible, so this pinning wins horizontally.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      final target = (index * widget.itemExtent).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _scroll.animateTo(
        target,
        duration: TvTokens.focusDuration,
        curve: TvTokens.focusCurve,
      );
    });
  }

  @override
  void didUpdateWidget(TvRow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadFocus = _nodes.any((node) => node.hasFocus);
    if (!hadFocus || widget.items.length == oldWidget.items.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.items.isEmpty) return;
      if (_nodes.any((node) => node.hasFocus)) return;
      final target = _lastIndex.clamp(0, widget.items.length - 1);
      final candidates = _nodeFor(target).traversalDescendants;
      if (candidates.isNotEmpty) candidates.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: _inset.left),
          child: Row(
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              if (widget.trailing != null) ...[
                const SizedBox(width: 16),
                widget.trailing!,
              ],
            ],
          ),
        ),
        // Trim the row to a whole number of cards so the last one is never cut.
        // The right inset is left out: scrolled, it would show the next card.
        LayoutBuilder(
          builder: (context, constraints) {
            final fit =
                ((constraints.maxWidth - _inset.left) ~/ widget.itemExtent)
                    .clamp(1, 1 << 20);
            return SizedBox(
              height: widget.height,
              width: fit * widget.itemExtent + _inset.left,
              child: _list(),
            );
          },
        ),
      ],
    );
  }

  Widget _list() => FocusTraversalGroup(
    child: ListView.builder(
      controller: _scroll,
      padding: _inset,
      scrollDirection: Axis.horizontal,
      itemExtent: widget.itemExtent,
      itemCount: widget.items.length,
      itemBuilder: (context, index) => Focus(
        focusNode: _nodeFor(index),
        onFocusChange: (focused) {
          if (focused) _onItemFocused(index);
        },
        child: Padding(
          padding: const EdgeInsets.only(right: TvTokens.posterGap),
          child: widget.itemBuilder(context, widget.items[index], index),
        ),
      ),
    ),
  );
}
