import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_shell.dart';
import '../l10n/app_localizations.dart';
import 'app_preferences.dart';
import 'theme.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late Locale? _locale;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _locale = widget.preferences.locale;
    _themeMode = widget.preferences.themeMode;
  }

  Future<void> _changeLocale(Locale locale) async {
    setState(() => _locale = locale);
    await _savePreference(() => widget.preferences.saveLocale(locale));
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await _savePreference(() => widget.preferences.saveThemeMode(mode));
  }

  Future<void> _savePreference(Future<void> Function() save) async {
    try {
      await save();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'app preferences',
          context: ErrorDescription('while saving an app preference'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: _locale,
    onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
    theme: appTheme,
    darkTheme: appDarkTheme,
    themeMode: _themeMode,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: AppShell(
      onLocaleChanged: _changeLocale,
      onThemeModeChanged: _changeThemeMode,
    ),
  );
}
