import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../l10n/app_localizations.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._(this.database);
  final AppDatabase database;
  Map<String, Object?> _values = {};
  int _onboardingStep = 0;
  bool _onboardingCompleted = false;

  static const onboardingStepKey = 'onboarding_step';
  static const onboardingCompletedKey = 'onboarding_completed';
  int get onboardingStep => _onboardingStep;
  bool get onboardingCompleted => _onboardingCompleted;

  static const themeModeKey = 'theme_mode';
  static const languageCodeKey = 'language_code';
  static const dailySummaryEnabledKey = 'daily_summary_enabled';
  static const reminderMinutesKey = 'daily_summary_minutes';
  static const summaryLedgerKey = 'daily_summary_ledger';
  static const summaryConsumedDayKey = 'daily_summary_consumed_day';

  static const portableKeys = {
    themeModeKey,
    languageCodeKey,
    dailySummaryEnabledKey,
    reminderMinutesKey,
  };
  static const runtimeKeys = {
    summaryLedgerKey,
    summaryConsumedDayKey,
    'reconcile_pending',
  };

  static Future<AppPreferences> load({AppDatabase? database}) async {
    final result = AppPreferences._(database ?? AppDatabase());
    final db = await result.database.database;
    await result.database.gate.run(() async {
      final migrated = (await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['preferences_migrated'],
      )).isNotEmpty;
      final legacy = !migrated
          ? await SharedPreferencesWithCache.create(
              cacheOptions: SharedPreferencesWithCacheOptions(
                allowList: {...portableKeys, ...runtimeKeys},
              ),
            )
          : null;
      final hasLegacy =
          legacy != null &&
          {
            ...portableKeys,
            ...runtimeKeys,
          }.any((key) => legacy.get(key) != null);
      final existing = migrated || !result.database.wasCreated || hasLegacy;
      await db.transaction((txn) async {
        if (!migrated) {
          for (final key in {...portableKeys, ...runtimeKeys}) {
            final value = legacy!.get(key);
            if (value != null) {
              await txn.insert(
                runtimeKeys.contains(key)
                    ? 'notification_runtime'
                    : 'app_settings',
                {'key': key, 'value': jsonEncode(value)},
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
          await txn.insert('app_metadata', {
            'key': 'preferences_migrated',
            'value': 'true',
          });
        }
        if ((await txn.query(
          'app_metadata',
          where: 'key = ?',
          whereArgs: [onboardingCompletedKey],
        )).isEmpty) {
          await txn.insert('app_metadata', {
            'key': onboardingCompletedKey,
            'value': jsonEncode(existing),
          });
          await txn.insert('app_metadata', {
            'key': onboardingStepKey,
            'value': '0',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          if (!existing) {
            await txn.insert('app_settings', {
              'key': themeModeKey,
              'value': jsonEncode(ThemeMode.system.name),
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      });
      await result.reload();
    });
    return result;
  }

  Future<void> reload() => database.gate.run(() async {
    final db = await database.database;
    final values = <String, Object?>{};
    for (final table in ['app_settings', 'notification_runtime']) {
      for (final row in await db.query(table)) {
        values[row['key'] as String] = jsonDecode(row['value'] as String);
      }
    }
    final metadata = await db.query('app_metadata');
    final state = {for (final row in metadata) row['key']: row['value']};
    _onboardingCompleted = state[onboardingCompletedKey] == 'true';
    _onboardingStep = (int.tryParse('${state[onboardingStepKey]}') ?? 0).clamp(
      0,
      3,
    );
    _values = values;
    notifyListeners();
  });

  Future<void> saveOnboardingStep(int step) => database.gate.run(() async {
    if (step < 0 || step > 3) throw ArgumentError.value(step, 'step');
    final db = await database.database;
    await db.insert('app_metadata', {
      'key': onboardingStepKey,
      'value': '$step',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _onboardingStep = step;
  });

  Future<void> completeOnboarding() => database.gate.run(() async {
    final db = await database.database;
    await db.insert('app_metadata', {
      'key': onboardingCompletedKey,
      'value': 'true',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _onboardingCompleted = true;
  });

  Future<void> restartOnboarding() => database.gate.run(() async {
    final db = await database.database;
    await db.transaction((txn) async {
      for (final entry in {
        onboardingCompletedKey: 'false',
        onboardingStepKey: '0',
      }.entries) {
        await txn.insert('app_metadata', {
          'key': entry.key,
          'value': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    _onboardingStep = 0;
    _onboardingCompleted = false;
  });

  Future<void> _save(String key, Object value) => database.gate.run(() async {
    final db = await database.database;
    await db.insert(
      runtimeKeys.contains(key) ? 'notification_runtime' : 'app_settings',
      {'key': key, 'value': jsonEncode(value)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _values = {..._values, key: value};
    if (portableKeys.contains(key)) notifyListeners();
  });

  bool get reconciliationPending => _values['reconcile_pending'] == true;
  Future<void> saveReconciliationPending(bool value) =>
      _save('reconcile_pending', value);

  ThemeMode get themeMode {
    final saved = _values[themeModeKey];
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.light,
    );
  }

  Locale? get locale {
    final saved = _values[languageCodeKey];
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == saved) return locale;
    }
    return const Locale('th');
  }

  Future<void> saveThemeMode(ThemeMode mode) => _save(themeModeKey, mode.name);

  Future<void> saveLocale(Locale locale) =>
      _save(languageCodeKey, locale.languageCode);

  bool get dailySummaryEnabled => _values[dailySummaryEnabledKey] == true;

  int get reminderMinutes {
    final value = _values[reminderMinutesKey];
    return value is int && value >= 0 && value < 1440 ? value : 9 * 60;
  }

  int get summaryConsumedDay {
    final value = _values[summaryConsumedDayKey];
    return value is int ? value : 0;
  }

  /// Calendar day -> scheduled instant. Survives restarts and time changes.
  Map<int, int> get summaryLedger {
    final value = _values[summaryLedgerKey];
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
      _save(dailySummaryEnabledKey, enabled);

  Future<void> saveReminderMinutes(int minutes) {
    if (minutes < 0 || minutes >= 1440) {
      throw ArgumentError.value(minutes, 'minutes');
    }
    return _save(reminderMinutesKey, minutes);
  }

  Future<void> saveSummaryConsumedDay(int day) =>
      _save(summaryConsumedDayKey, day);

  Future<void> saveSummaryLedger(Map<int, int> ledger) => _save(
    summaryLedgerKey,
    jsonEncode({
      for (final entry in ledger.entries) entry.key.toString(): entry.value,
    }),
  );
}
