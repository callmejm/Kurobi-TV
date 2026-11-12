import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/tv/tv_theme.dart';

/// D-pad focus target: scales up and draws a white ring with a soft glow while
/// focused, and calls [onSelect] on OK / Enter / gamepad A (or a tap, for
/// pointer testing).
///
/// Pass [builder] instead of [child] when the content itself changes with
/// focus (pills invert their fill); set [ring] false for those.
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    this.child,
    this.builder,
    required this.onSelect,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    this.borderRadius = TvTokens.cardRadius,
    this.scale = TvTokens.focusScale,
    this.ring = true,
  }) : assert(child != null || builder != null);

  final Widget? child;
  final Widget Function(BuildContext context, bool focused)? builder;
  final VoidCallback onSelect;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final BorderRadius borderRadius;
  final double scale;
  final bool ring;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  static final _selectKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.gameButtonA,
  };

  // A node handed over from a rebuilt widget can already hold focus, and then
  // no focus change is reported.
  late bool _focused = widget.focusNode?.hasFocus ?? false;

  void _onFocusChange(bool focused) {
    setState(() => _focused = focused);
    widget.onFocusChange?.call(focused);
    if (focused) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: TvTokens.focusDuration,
        curve: TvTokens.focusCurve,
      );
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && _selectKeys.contains(event.logicalKey)) {
      widget.onSelect();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.builder?.call(context, _focused) ?? widget.child!;
    final showRing = widget.ring && _focused;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _onFocusChange,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedScale(
          scale: _focused ? widget.scale : 1.0,
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: showRing
                  ? Border.all(color: TvTokens.focus, width: 2.5)
                  : null,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                boxShadow: _focused
                    ? const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Makes the remote work on Material pages reused as-is (the phone settings),
/// for arrow presses no widget handled:
/// - with only a route scope focused, it focuses the page's first control;
/// - at the edge of a nested scope (a page's own navigator, like the settings
///   pane), it moves to the nearest control of the current route beyond it.
class TvFocusRescue extends StatelessWidget {
  const TvFocusRescue({super.key, required this.child});

  final Widget child;

  static final _directions = {
    LogicalKeyboardKey.arrowUp: TraversalDirection.up,
    LogicalKeyboardKey.arrowDown: TraversalDirection.down,
    LogicalKeyboardKey.arrowLeft: TraversalDirection.left,
    LogicalKeyboardKey.arrowRight: TraversalDirection.right,
  };

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    final direction = _directions[event.logicalKey];
    final primary = FocusManager.instance.primaryFocus;
    if (event is KeyUpEvent || direction == null || primary == null) {
      return KeyEventResult.ignored;
    }
    if (primary is FocusScopeNode) {
      primary.nextFocus();
      return KeyEventResult.handled;
    }
    // Text fields use arrows to move the cursor.
    if (primary.context?.findAncestorWidgetOfExactType<EditableText>() !=
        null) {
      return KeyEventResult.ignored;
    }
    if (primary.focusInDirection(direction)) return KeyEventResult.handled;
    final next = tvNearestInDirection(primary, direction);
    if (next == null) return KeyEventResult.ignored;
    next.requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: child,
    );
  }
}

/// The focusable node of a current route nearest to [from] in [direction],
/// searching every scope [from] sits in, not only its own.
FocusNode? tvNearestInDirection(FocusNode from, TraversalDirection direction) {
  final origin = from.rect;
  bool beyond(Rect r) => switch (direction) {
    TraversalDirection.left => r.right <= origin.left + 1,
    TraversalDirection.right => r.left >= origin.right - 1,
    TraversalDirection.up => r.bottom <= origin.top + 1,
    TraversalDirection.down => r.top >= origin.bottom - 1,
  };
  final vertical =
      direction == TraversalDirection.up ||
      direction == TraversalDirection.down;
  double score(Rect r) {
    final d = r.center - origin.center;
    // Prefer nodes in line with the origin over diagonal ones.
    return vertical ? d.dy.abs() + 2 * d.dx.abs() : d.dx.abs() + 2 * d.dy.abs();
  }

  final root = FocusManager.instance.rootScope;
  FocusNode? best;
  for (final node in root.traversalDescendants) {
    if (node is FocusScopeNode || node == from || node.context == null) {
      continue;
    }
    if (!(ModalRoute.of(node.context!)?.isCurrent ?? true)) continue;
    if (!beyond(node.rect)) continue;
    if (best == null || score(node.rect) < score(best.rect)) best = node;
  }
  return best;
}

/// Pill button: translucent at rest, solid white with dark text when focused.
class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    required this.label,
    required this.onSelect,
    this.icon,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onSelect;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  /// Marks the current choice (active tab, chosen day) when not focused.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      onSelect: onSelect,
      ring: false,
      scale: 1.05,
      borderRadius: TvTokens.pillRadius,
      builder: (context, focused) {
        final foreground = focused
            ? Colors.black
            : (selected ? TvTokens.text : TvTokens.textMuted);
        return AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          color: focused
              ? TvTokens.focus
              : (selected
                    ? accent.withValues(alpha: 0.28)
                    : const Color(0x1FFFFFFF)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(color: foreground),
              ),
            ],
          ),
        );
      },
    );
  }
}
