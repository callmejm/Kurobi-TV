import 'package:flutter/material.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

/// Poster tile: [cover] fills the top, then a title clamped to two lines and
/// an optional one-line [subtitle]. Fill the slot the parent gives it.
class TvPosterCard extends StatelessWidget {
  const TvPosterCard({
    super.key,
    required this.title,
    required this.cover,
    required this.onSelect,
    this.subtitle,
    this.autofocus = false,
    this.focusNode,
  });

  final String title;
  final String? subtitle;
  final Widget cover;
  final VoidCallback onSelect;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onSelect: onSelect,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cover),
            SizedBox(
              height: 96,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
