import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class AppPreferences {
  AppPreferences._(this._preferences);

  static const themeModeKey = 'theme_mode';
  static const languageCodeKey = 'language_code';
  static const dailySummaryEnabledKey = 'daily_summary_enabled';
  static const reminderMinutesKey = 'daily_summary_minutes';
  static const summaryLedgerKey = 'daily_summary_ledger';
  static const summaryConsumedDayKey = 'daily_summary_consumed_day';

  final SharedPreferencesWithCache _preferences;

  static Future<AppPreferences> load() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {
          themeModeKey,
          languageCodeKey,
          dailySummaryEnabledKey,
          reminderMinutesKey,
          summaryLedgerKey,
          summaryConsumedDayKey,
        },
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

  bool get dailySummaryEnabled =>
      _preferences.get(dailySummaryEnabledKey) == true;

  int get reminderMinutes {
    final value = _preferences.get(reminderMinutesKey);
    return value is int && value >= 0 && value < 1440 ? value : 9 * 60;
  }

  int get summaryConsumedDay {
    final value = _preferences.get(summaryConsumedDayKey);
    return value is int ? value : 0;
  }

  /// Calendar day -> scheduled instant. Survives restarts and time changes.
  Map<int, int> get summaryLedger {
    final value = _preferences.get(summaryLedgerKey);
    if (value is! String) return {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (int.tryParse(entry.key.toString()) != null && entry.value is int)
            int.parse(entry.key.toString()): entry.value as int,
      };
    } on FormatException {
      return {};
    }
  }

  Future<void> saveDailySummaryEnabled(bool enabled) =>
      _preferences.setBool(dailySummaryEnabledKey, enabled);

  Future<void> saveReminderMinutes(int minutes) {
    if (minutes < 0 || minutes >= 1440) {
      throw ArgumentError.value(minutes, 'minutes');
    }
    return _preferences.setInt(reminderMinutesKey, minutes);
  }

  Future<void> saveSummaryConsumedDay(int day) =>
      _preferences.setInt(summaryConsumedDayKey, day);

  Future<void> saveSummaryLedger(Map<int, int> ledger) =>
      _preferences.setString(
        summaryLedgerKey,
        jsonEncode({
          for (final entry in ledger.entries) entry.key.toString(): entry.value,
        }),
      );
}
