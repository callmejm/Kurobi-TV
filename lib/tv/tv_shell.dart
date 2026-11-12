import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/tv/tv_routes.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

class TvDestination {
  const TvDestination(this.label, this.icon, this.path);

  final String label;
  final IconData? icon;
  final String path;
}

const tvDestinations = [
  TvDestination('搜索', Icons.search_rounded, TvRoutes.search),
  TvDestination('首页', null, TvRoutes.home),
  TvDestination('时间表', null, TvRoutes.timeline),
  TvDestination('收藏', null, TvRoutes.collect),
  TvDestination('历史', null, TvRoutes.history),
  TvDestination('规则', null, TvRoutes.rules),
];

/// Top navigation bar floating over full-bleed page content.
///
/// D-pad: Up from the top of a page reaches the bar, Down from the bar enters
/// the page. Back from a page focuses the active tab; Back on the bar goes to
/// Home, and on Home calls [onExit] (defaults to closing the app). Pages leave [TvTokens.navHeight]
/// free at the top (see [TvTokens.pagePadding]).
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
  final List<FocusNode> _navNodes = [
    for (final d in tvDestinations) FocusNode(debugLabel: 'nav ${d.label}'),
  ];

  int get _activeIndex {
    final index = tvDestinations.indexWhere(
      (d) => widget.location.startsWith(d.path),
    );
    return index < 0 ? 1 : index;
  }

  bool get _navFocused =>
      _navNodes.any((node) => node == FocusManager.instance.primaryFocus);

  static const _homeIndex = 1;

  void _handleBack() {
    if (_navFocused && _activeIndex != _homeIndex) {
      // TV convention: Back walks back to Home before it leaves the app.
      widget.onNavigate(tvDestinations[_homeIndex].path);
      _navNodes[_homeIndex].requestFocus();
    } else if (_navFocused) {
      (widget.onExit ?? SystemNavigator.pop).call();
    } else {
      _navNodes[_activeIndex].requestFocus();
    }
  }

  /// Up from content: move within the page if possible, else reach the bar.
  /// Needed because each page is its own focus scope whose edge stops.
  KeyEventResult _onContentKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.arrowUp ||
        _navFocused) {
      return KeyEventResult.ignored;
    }
    final moved = FocusManager.instance.primaryFocus?.focusInDirection(
      TraversalDirection.up,
    );
    if (moved != true) _navNodes[_activeIndex].requestFocus();
    return KeyEventResult.handled;
  }

  /// Left/Right on the bar step one tab. Flutter's directional traversal
  /// "reverses" to remembered nodes across scopes and could leave the bar.
  KeyEventResult _onNavKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      _ => 0,
    };
    final index = _navNodes.indexWhere((n) => n.hasPrimaryFocus);
    if (step == 0 || index < 0) return KeyEventResult.ignored;
    final next = index + step;
    if (next >= 0 && next < _navNodes.length) _navNodes[next].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    for (final node in _navNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Widget _navBar(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE60A0A0C), Color(0x000A0A0C)],
        ),
      ),
      child: SizedBox(
        height: TvTokens.navHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TvTokens.edgeH,
            TvTokens.edgeV - 6,
            TvTokens.edgeH,
            0,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onNavKey,
              child: Row(
                children: [
                  Text(
                    'Kazumi',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 28),
                  for (var i = 0; i < tvDestinations.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TvButton(
                        focusNode: _navNodes[i],
                        label: tvDestinations[i].label,
                        icon: tvDestinations[i].icon,
                        selected: i == _activeIndex,
                        onSelect: () =>
                            widget.onNavigate(tvDestinations[i].path),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          body: Stack(
            fit: StackFit.expand,
            children: [
              Focus(onKeyEvent: _onContentKey, child: widget.child),
              Positioned(top: 0, left: 0, right: 0, child: _navBar(context)),
            ],
          ),
        ),
      ),
    );
  }
}
