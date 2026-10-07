import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/app_preferences.dart';
import 'package:longdow_todo_list/core/database/app_database.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late AppDatabase database;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('preferences_migration_');
    final path = '${directory.path}/todos.db';
    final old = await databaseFactoryFfiNoIsolate.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('''CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
        details TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'medium', created_at TEXT NOT NULL,
        due_date TEXT)'''),
      ),
    );
    await old.insert('todos', {
      'title': 'Existing',
      'details': '',
      'created_at': '2026-10-06T08:00:00Z',
    });
    await old.close();
    database = AppDatabase(factory: databaseFactoryFfiNoIsolate, path: path);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          AppPreferences.themeModeKey: 'dark',
          AppPreferences.languageCodeKey: 'th',
          AppPreferences.dailySummaryEnabledKey: true,
          AppPreferences.reminderMinutesKey: 615,
          AppPreferences.summaryLedgerKey: '{"20261006":1234}',
          AppPreferences.summaryConsumedDayKey: 20261005,
        });
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'upgrade preserves Todos and imports settings/runtime exactly once',
    () async {
      final preferences = await AppPreferences.load(database: database);
      expect(await (await database.database).getVersion(), 2);
      expect((await TodoService(database).getTodos()).single.title, 'Existing');
      expect(preferences.themeMode, ThemeMode.dark);
      expect(preferences.locale, const Locale('th'));
      expect(preferences.dailySummaryEnabled, isTrue);
      expect(preferences.reminderMinutes, 615);
      expect(preferences.summaryLedger, {20261006: 1234});
      expect(preferences.summaryConsumedDay, 20261005);
      await preferences.saveThemeMode(ThemeMode.light);
      await preferences.saveLocale(const Locale('en'));
      preferences.dispose();
      await database.close();
      // Stale SharedPreferences still say dark/Thai; SQLite is authoritative.
      final reopened = await AppPreferences.load(database: database);
      expect(reopened.themeMode, ThemeMode.light);
      expect(reopened.locale, const Locale('en'));
      expect(reopened.reminderMinutes, 615);
      reopened.dispose();
    },
  );

  test(
    'failed migration leaves no partial settings/marker and retries safely',
    () async {
      final db = await database.database;
      await db.execute(
        "CREATE TRIGGER reject_setting BEFORE INSERT ON app_settings WHEN NEW.key = 'theme_mode' BEGIN SELECT RAISE(ABORT, 'injected migration failure'); END",
      );
      await expectLater(
        AppPreferences.load(database: database),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('app_settings'), isEmpty);
      expect(await db.query('notification_runtime'), isEmpty);
      expect(await db.query('app_metadata'), isEmpty);
      expect((await TodoService(database).getTodos()).single.title, 'Existing');
      await db.execute('DROP TRIGGER reject_setting');
      final preferences = await AppPreferences.load(database: database);
      expect(preferences.themeMode, ThemeMode.dark);
      expect(preferences.dailySummaryEnabled, isTrue);
      expect(await db.query('app_metadata'), hasLength(3));
      expect(preferences.onboardingCompleted, isTrue);
      preferences.dispose();
    },
  );
}
