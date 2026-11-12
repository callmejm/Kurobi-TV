import 'package:flutter/material.dart';
import 'package:kazumi/tv/tv_theme.dart';

/// Six-column poster grid sized for the 960 dp canvas.
class TvPosterGrid<T> extends StatelessWidget {
  const TvPosterGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(TvTokens.itemInset),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: TvTokens.posterGap,
        mainAxisSpacing: 20,
        // 2:3 artwork at ~131 dp wide plus title and subtitle lines.
        mainAxisExtent: 266,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          itemBuilder(context, items[index], index),
    );
  }
}
