import 'package:flutter/material.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

/// Centered message with an optional focused action (retry, open rules, ...).
class TvMessage extends StatefulWidget {
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
  State<TvMessage> createState() => _TvMessageState();
}

class _TvMessageState extends State<TvMessage> {
  final _actionNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // autofocus is ignored when another node already has focus, so ask directly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _actionNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _actionNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final actionLabel = widget.actionLabel;
    final onAction = widget.onAction;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: Theme.of(context).textTheme.titleLarge),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            TvFocusable(
              focusNode: _actionNode,
              onSelect: onAction,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  child: Text(actionLabel),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
