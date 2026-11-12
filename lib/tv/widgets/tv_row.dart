import 'package:flutter/material.dart';

/// Titled horizontal row of D-pad focusable items.
///
/// If the focused item disappears (list reloaded or shortened), focus moves to
/// the item now at the same position, or the last one, so it is never lost.
/// Entering a row from another row uses Flutter's geometric traversal.
class TvRow<T> extends StatefulWidget {
  const TvRow({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.itemExtent = 200,
    this.height = 300,
  });

  final String title;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double itemExtent;
  final double height;

  @override
  State<TvRow<T>> createState() => _TvRowState<T>();
}

class _TvRowState<T> extends State<TvRow<T>> {
  final List<FocusNode> _nodes = [];
  int _lastIndex = 0;

  FocusNode _nodeFor(int index) {
    while (_nodes.length <= index) {
      _nodes.add(FocusNode(skipTraversal: true, canRequestFocus: false));
    }
    return _nodes[index];
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: widget.height,
          child: FocusTraversalGroup(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemExtent: widget.itemExtent,
              itemCount: widget.items.length,
              itemBuilder: (context, index) => Focus(
                focusNode: _nodeFor(index),
                onFocusChange: (focused) {
                  if (focused) _lastIndex = index;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: widget.itemBuilder(
                    context,
                    widget.items[index],
                    index,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
