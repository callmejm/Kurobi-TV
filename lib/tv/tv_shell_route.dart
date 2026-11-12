import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/services/platform/app_exit.dart';
import 'package:kazumi/tv/tv_shell.dart';

/// Hosts [TvShell] and switches destinations inside its own [RouterOutlet],
/// so the shell, its focus and its controllers survive a switch (like the
/// phone's ScaffoldMenu). Calling `context.navigate` here would rebuild the
/// whole shell instead.
class TvShellRoute extends StatefulWidget {
  const TvShellRoute({super.key, required this.location});

  final String location;

  @override
  State<TvShellRoute> createState() => _TvShellRouteState();
}

class _TvShellRouteState extends State<TvShellRoute> {
  final _outletKey = GlobalKey<RouterOutletState>();
  late String _location = widget.location;

  void _navigate(String path) {
    _outletKey.currentState?.navigate(path);
    setState(() => _location = path);
  }

  @override
  Widget build(BuildContext context) {
    return TvShell(
      location: _location,
      onNavigate: _navigate,
      // End the process: the audio service would otherwise keep it alive.
      onExit: AppExit.quit,
      child: RouterOutlet(key: _outletKey),
    );
  }
}
