import 'package:flutter/material.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

/// Poster tile: 2:3 [cover] artwork, then a title clamped to two lines and an
/// optional one-line [subtitle] on the page background. Only the artwork gets
/// the focus ring; the title brightens.
class TvPosterCard extends StatelessWidget {
  const TvPosterCard({
    super.key,
    required this.title,
    required this.cover,
    required this.onSelect,
    this.subtitle,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
  });

  final String title;
  final String? subtitle;
  final Widget cover;
  final VoidCallback onSelect;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      onSelect: onSelect,
      ring: false,
      borderRadius: BorderRadius.zero,
      builder: (context, focused) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: TvTokens.cardRadius,
                border: focused
                    ? Border.all(color: TvTokens.focus, width: 2.5)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: TvTokens.cardRadius,
                child: ColoredBox(color: TvTokens.surface, child: cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium!.copyWith(
              color: focused ? TvTokens.text : TvTokens.textMuted,
              fontWeight: focused ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall!.copyWith(color: TvTokens.textMuted),
            ),
        ],
      ),
    );
  }
}
