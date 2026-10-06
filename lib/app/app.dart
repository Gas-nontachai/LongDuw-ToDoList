import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/notifications/widgets/daily_summary_host.dart';
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
  @override
  void initState() {
    super.initState();
    widget.preferences.addListener(_preferencesChanged);
  }

  @override
  void didUpdateWidget(covariant TodoApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      oldWidget.preferences.removeListener(_preferencesChanged);
      widget.preferences.addListener(_preferencesChanged);
    }
  }

  void _preferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.preferences.removeListener(_preferencesChanged);
    super.dispose();
  }

  Future<void> _changeLocale(Locale locale) =>
      _savePreference(() => widget.preferences.saveLocale(locale));

  Future<void> _changeThemeMode(ThemeMode mode) =>
      _savePreference(() => widget.preferences.saveThemeMode(mode));

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
    locale: widget.preferences.locale,
    onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
    theme: appTheme,
    darkTheme: appDarkTheme,
    themeMode: widget.preferences.themeMode,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: DailySummaryHost(
      preferences: widget.preferences,
      onLocaleChanged: _changeLocale,
      onThemeModeChanged: _changeThemeMode,
    ),
  );
}
