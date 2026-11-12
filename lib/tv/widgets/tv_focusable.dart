import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// D-pad focus target: draws a ring and scales up while focused, and calls
/// [onSelect] on OK / Enter / gamepad A (or a tap, for pointer testing).
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.child,
    required this.onSelect,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final Widget child;
  final VoidCallback onSelect;
  final bool autofocus;
  final FocusNode? focusNode;
  final BorderRadius borderRadius;

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

  bool _focused = false;

  void _onFocusChange(bool focused) {
    setState(() => _focused = focused);
    if (focused) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 150),
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
    final ring = Theme.of(context).colorScheme.primary;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _onFocusChange,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedScale(
          scale: _focused ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: _focused ? Border.all(color: ring, width: 3) : null,
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
