import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/tv/tv_routes.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

class TvDestination {
  const TvDestination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}

const tvDestinations = [
  TvDestination('首页', Icons.home_rounded, TvRoutes.home),
  TvDestination('时间表', Icons.calendar_month_rounded, TvRoutes.timeline),
  TvDestination('收藏', Icons.favorite_rounded, TvRoutes.collect),
  TvDestination('历史', Icons.history_rounded, TvRoutes.history),
  TvDestination('搜索', Icons.search_rounded, TvRoutes.search),
  TvDestination('规则', Icons.extension_rounded, TvRoutes.rules),
];

/// Left navigation rail plus content, inside the TV overscan-safe area.
///
/// Back: from content it returns focus to the active rail item; on the rail it
/// calls [onExit] (defaults to closing the app).
class TvShell extends StatefulWidget {
  const TvShell({
    super.key,
    required this.location,
    required this.child,
    required this.onNavigate,
    this.onExit,
  });

  final String location;
  final Widget child;
  final void Function(String path) onNavigate;
  final VoidCallback? onExit;

  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  final List<FocusNode> _railNodes = [
    for (final _ in tvDestinations) FocusNode(),
  ];

  int get _activeIndex {
    final index = tvDestinations.indexWhere(
      (d) => widget.location.startsWith(d.path),
    );
    return index < 0 ? 0 : index;
  }

  void _handleBack() {
    final primary = FocusManager.instance.primaryFocus;
    if (_railNodes.any((node) => node == primary)) {
      (widget.onExit ?? SystemNavigator.pop).call();
    } else {
      _railNodes[_activeIndex].requestFocus();
    }
  }

  /// Left from content: move within content if possible, else reach the rail.
  /// Needed because each outlet page is its own focus scope whose edge stops.
  KeyEventResult _onContentKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.arrowLeft) {
      return KeyEventResult.ignored;
    }
    final moved = FocusManager.instance.primaryFocus?.focusInDirection(
      TraversalDirection.left,
    );
    if (moved != true) _railNodes[_activeIndex].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    for (final node in _railNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _handleBack,
        },
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 27),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: FocusTraversalGroup(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < tvDestinations.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: TvFocusable(
                              focusNode: _railNodes[i],
                              onSelect: () =>
                                  widget.onNavigate(tvDestinations[i].path),
                              child: Container(
                                color: i == _activeIndex
                                    ? scheme.primaryContainer
                                    : scheme.surfaceContainerHighest,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(tvDestinations[i].icon),
                                    const SizedBox(width: 12),
                                    Text(tvDestinations[i].label),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Focus(onKeyEvent: _onContentKey, child: widget.child),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
