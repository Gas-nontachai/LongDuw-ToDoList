import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/todo/screens/todo_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  void _changeLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  void _changeThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
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
    home: TodoScreen(
      onLocaleChanged: _changeLocale,
      onThemeModeChanged: _changeThemeMode,
    ),
  );
}
