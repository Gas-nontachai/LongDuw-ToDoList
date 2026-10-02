import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class AppPreferences {
  AppPreferences._(this._preferences);

  static const themeModeKey = 'theme_mode';
  static const languageCodeKey = 'language_code';

  final SharedPreferencesWithCache _preferences;

  static Future<AppPreferences> load() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {themeModeKey, languageCodeKey},
      ),
    );
    return AppPreferences._(preferences);
  }

  ThemeMode get themeMode {
    final saved = _preferences.get(themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Locale? get locale {
    final saved = _preferences.get(languageCodeKey);
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == saved) return locale;
    }
    return null;
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _preferences.setString(themeModeKey, mode.name);

  Future<void> saveLocale(Locale locale) =>
      _preferences.setString(languageCodeKey, locale.languageCode);
}
