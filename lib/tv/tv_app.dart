import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/navigation.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/tv/tv_theme.dart';

/// Root widget of the TV UI. Replaces `AppWidget`; no tray, window or dynamic color.
class TvApp extends StatelessWidget {
  const TvApp({super.key});

  Color _seedColor() {
    final stored = GStorage.getSetting(SettingsKeys.themeColor);
    if (stored == 'default') return Colors.green;
    return Color(int.parse(stored, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    const locale = Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
      countryCode: 'CN',
    );
    return MaterialApp.router(
      title: 'Kazumi',
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [locale],
      locale: locale,
      theme: buildTvTheme(seed: _seedColor()),
      themeMode: ThemeMode.dark,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: ModularApp.routerConfigOf(context),
    );
  }
}
