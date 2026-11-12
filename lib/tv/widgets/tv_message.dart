import 'package:flutter/material.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

/// Centered message with an optional focused action (retry, open rules, ...).
class TvMessage extends StatelessWidget {
  const TvMessage({
    super.key,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: Theme.of(context).textTheme.titleLarge),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            TvFocusable(
              autofocus: true,
              onSelect: onAction!,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
