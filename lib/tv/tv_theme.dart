import 'package:flutter/material.dart';

const double tvTextScale = 1.3;

/// Dark-only theme for the TV UI.
ThemeData buildTvTheme({Color seed = Colors.green}) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: seed,
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
  );
}

/// Scales all text by [tvTextScale] for couch viewing distance.
class TvTextScale extends StatelessWidget {
  const TvTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(tvTextScale)),
      child: child,
    );
  }
}
