import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/app_preferences.dart';
import 'package:longdow_todo_list/core/database/app_database.dart';
import 'package:longdow_todo_list/features/backup/services/backup_service.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestPreferences fixture;
  setUp(() {
    fixture = TestPreferences();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => fixture.close());

  test(
    'fresh install is off, Thai/system and resumes each checkpoint',
    () async {
      var prefs = await fixture.load(completeOnboarding: false);
      expect(prefs.onboardingCompleted, isFalse);
      expect(prefs.onboardingStep, 0);
      expect(prefs.themeMode, ThemeMode.system);
      expect(prefs.locale, const Locale('th'));
      expect(prefs.dailySummaryEnabled, isFalse);
      for (var step = 1; step < 4; step++) {
        await prefs.saveOnboardingStep(step);
        prefs = await fixture.load(completeOnboarding: false);
        expect(prefs.onboardingStep, step);
        expect(prefs.onboardingCompleted, isFalse);
      }
      await prefs.completeOnboarding();
      expect(
        (await fixture.load(completeOnboarding: false)).onboardingCompleted,
        isTrue,
      );
      await expectLater(prefs.saveOnboardingStep(4), throwsArgumentError);
    },
  );

  test(
    'first task commits completion atomically and rejects duplicate requests',
    () async {
      final prefs = await fixture.load(completeOnboarding: false);
      final service = TodoService(fixture.database);
      final due = DateTime(2026, 10, 7);
      final created = await service.createOnboardingTodo(
        '  Read  ',
        priority: 'high',
        dueDate: due,
      );
      expect(created.title, 'Read');
      expect(created.dueDate, due);
      expect(created.completed, isFalse);
      final reopened = await fixture.load(completeOnboarding: false);
      expect(reopened.onboardingCompleted, isTrue);
      await expectLater(
        service.createOnboardingTodo('Duplicate'),
        throwsStateError,
      );
      expect(await service.getTodos(), hasLength(1));
      await prefs.reload();
      expect(prefs.onboardingCompleted, isTrue);
    },
  );

  test(
    'failed completion rolls back first task, then retry creates one task',
    () async {
      final prefs = await fixture.load(completeOnboarding: false);
      final db = await fixture.database.database;
      final service = TodoService(fixture.database);
      await db.execute(
        "CREATE TRIGGER reject_onboarding BEFORE INSERT ON app_metadata WHEN NEW.key = 'onboarding_completed' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      await expectLater(
        service.createOnboardingTodo('Read'),
        throwsA(isA<DatabaseException>()),
      );
      expect(await service.getTodos(), isEmpty);
      await prefs.reload();
      expect(prefs.onboardingCompleted, isFalse);
      await db.execute('DROP TRIGGER reject_onboarding');
      await service.createOnboardingTodo('Read');
      await prefs.reload();
      expect(prefs.onboardingCompleted, isTrue);
      expect(await service.getTodos(), hasLength(1));
    },
  );

  test('invalid first task does not complete onboarding', () async {
    final prefs = await fixture.load(completeOnboarding: false);
    final service = TodoService(fixture.database);
    await expectLater(service.createOnboardingTodo('   '), throwsArgumentError);
    await expectLater(
      service.createOnboardingTodo('Read', priority: 'invalid'),
      throwsArgumentError,
    );
    expect(await service.getTodos(), isEmpty);
    await prefs.reload();
    expect(prefs.onboardingCompleted, isFalse);
  });

  test('legacy preferences preserve choices and bypass introduction', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          AppPreferences.themeModeKey: 'dark',
          AppPreferences.languageCodeKey: 'en',
        });
    final prefs = await fixture.load(completeOnboarding: false);
    expect(prefs.onboardingCompleted, isTrue);
    expect(prefs.themeMode, ThemeMode.dark);
    expect(prefs.locale, const Locale('en'));
  });

  test(
    'backup excludes local progress and restore preserves destination progress',
    () async {
      final prefs = await fixture.load(completeOnboarding: false);
      await prefs.saveOnboardingStep(2);
      final service = BackupService(preferences: prefs);
      final backup = await service.create(appVersion: '1.0.0');
      expect(
        backup.backup.appSettings.keys,
        unorderedEquals(['themeMode', 'languageCode']),
      );
      expect(String.fromCharCodes(backup.bytes), isNot(contains('onboarding')));
      await prefs.completeOnboarding();
      await service.restore(backup.backup);
      await prefs.reload();
      expect(prefs.onboardingCompleted, isTrue);
      expect(prefs.onboardingStep, 2);
      await prefs.restartOnboarding();
      expect(prefs.onboardingCompleted, isFalse);
      expect(prefs.onboardingStep, 0);
      expect(prefs.themeMode, ThemeMode.system);
    },
  );

  test(
    'disk reopen resumes progress; preexisting empty database skips onboarding',
    () async {
      final directory = await Directory.systemTemp.createTemp('onboarding_');
      final database = AppDatabase(
        factory: databaseFactoryFfiNoIsolate,
        path: '${directory.path}/tasks.db',
      );
      try {
        final fresh = await AppPreferences.load(database: database);
        await fresh.saveOnboardingStep(2);
        fresh.dispose();
        await database.close();
        final resumed = await AppPreferences.load(database: database);
        expect(resumed.onboardingStep, 2);
        expect(resumed.onboardingCompleted, isFalse);
        resumed.dispose();
        // Simulate an existing v2 install without the new onboarding metadata.
        final db = await database.database;
        await db.delete('app_metadata');
        await db.delete('app_settings');
        await database.close();
        final existing = await AppPreferences.load(database: database);
        expect(existing.onboardingCompleted, isTrue);
        expect(existing.themeMode, ThemeMode.light);
        existing.dispose();
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
