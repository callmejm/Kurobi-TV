import 'package:flutter/material.dart';

/// Design tokens for the TV UI. Android TV lays out on a 960x540 dp canvas;
/// sizes here are tuned for that canvas viewed from a couch.
abstract final class TvTokens {
  // Overscan-safe margins (5% of 960x540).
  static const double edgeH = 48;
  static const double edgeV = 27;

  static const Color background = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF17171B);
  static const Color surfaceHigh = Color(0xFF26262C);
  static const Color text = Color(0xFFF4F4F6);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color focus = Colors.white;

  static const double radius = 12;
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(radius),
  );
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));

  static const double focusScale = 1.08;
  static const Duration focusDuration = Duration(milliseconds: 160);
  static const Curve focusCurve = Curves.easeOutCubic;

  /// Height of the top navigation bar, overscan included.
  static const double navHeight = 84;

  /// Rows and grids pad their items by [itemInset] for the focus scale, so
  /// page content sits [itemInset] inside the overscan edge.
  static const double itemInset = 10;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    edgeH - itemInset,
    navHeight,
    edgeH - itemInset,
    0,
  );

  // Poster row: 2:3 artwork plus two title lines.
  static const double posterWidth = 128;
  static const double posterHeight = 192;
  static const double posterGap = 16;
}

/// Dark-only theme for the TV UI with an explicit type scale.
ThemeData buildTvTheme({Color seed = Colors.green}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  ).copyWith(surface: TvTokens.background, onSurface: TvTokens.text);
  const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 15, height: 1.5),
    bodyMedium: TextStyle(fontSize: 13, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, height: 1.3),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: TvTokens.background,
    textTheme: textTheme.apply(
      bodyColor: TvTokens.text,
      displayColor: TvTokens.text,
    ),
    // TV widgets draw remote focus with TvFocusable and use no ink, so the
    // focus color only shows on Material pages reused as-is (settings).
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    focusColor: const Color(0x52FFFFFF),
  );
}
