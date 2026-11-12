import 'package:flutter/material.dart';
import 'package:kazumi/tv/tv_theme.dart';
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
    final actionLabel = widget.actionLabel;
    final onAction = widget.onAction;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge!.copyWith(color: TvTokens.textMuted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            TvButton(
              focusNode: _actionNode,
              label: actionLabel,
              onSelect: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
