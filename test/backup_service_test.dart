import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/app_preferences.dart';
import 'package:longdow_todo_list/core/database/app_database.dart';
import 'package:longdow_todo_list/features/backup/models/backup_package.dart';
import 'package:longdow_todo_list/features/backup/services/backup_service.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Object? sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: sorted(value[key])};
  }
  if (value is List) return value.map(sorted).toList();
  return value;
}

Uint8List changeBackup(
  Uint8List bytes,
  void Function(Map<String, dynamic>) change, {
  bool checksum = true,
}) {
  final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  change(json);
  if (checksum) {
    json.remove('checksum');
    json['checksum'] = sha256
        .convert(utf8.encode(jsonEncode(sorted(json))))
        .toString();
  }
  return Uint8List.fromList(utf8.encode(jsonEncode(json)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late AppDatabase database;
  late AppPreferences preferences;
  late TodoService todos;
  late BackupService backups;
  const codec = BackupCodec();

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    directory = await Directory.systemTemp.createTemp('backup_test_');
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: '${directory.path}/todos.db',
    );
    preferences = await AppPreferences.load(database: database);
    todos = TodoService(database);
    backups = BackupService(preferences: preferences);
  });
  tearDown(() async {
    preferences.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<BackupSnapshot> sample() async {
    final first = await todos.createTodo(
      'งานภาษาไทย',
      'บรรทัดแรก\nบรรทัดที่สอง',
      priority: 'high',
      dueDate: DateTime(2026, 10, 7),
    );
    await todos.updateTodo(first.copyWith(completed: true));
    await todos.createTodo('No due date', '', priority: 'low');
    await preferences.saveThemeMode(ThemeMode.dark);
    await preferences.saveLocale(const Locale('th'));
    await preferences.saveDailySummaryEnabled(true);
    await preferences.saveReminderMinutes(600);
    await preferences.saveSummaryLedger({20261006: 1234});
    await preferences.saveSummaryConsumedDay(20261006);
    return backups.create(
      appVersion: '1.0.0',
      now: DateTime.utc(2026, 10, 6, 8, 30),
    );
  }

  test('round trip replaces every task/setting, keeps IDs and drops device runtime', () async {
    final snapshot = await sample();
    final original = (await todos.getTodos()).map((t) => t.toJson()).toList();
    expect(utf8.decode(snapshot.bytes), isNot(contains('ledger')));
    expect(utf8.decode(snapshot.bytes), isNot(contains('consumed')));
    await todos.createTodo('Must disappear', '');
    await preferences.saveThemeMode(ThemeMode.light);
    await preferences.saveLocale(const Locale('en'));
    await preferences.saveReminderMinutes(700);
    await preferences.saveDailySummaryEnabled(false);
    await backups.restore(snapshot.backup);
    await preferences.reload();
    expect((await todos.getTodos()).map((t) => t.toJson()).toList(), original);
    expect(preferences.themeMode, ThemeMode.dark);
    expect(preferences.locale, const Locale('th'));
    expect(preferences.dailySummaryEnabled, isTrue);
    expect(preferences.reminderMinutes, 600);
    expect(preferences.summaryLedger, isEmpty);
    expect(preferences.summaryConsumedDay, 0);
    expect(preferences.reconciliationPending, isTrue);
    final next = await todos.createTodo('New', '');
    expect(int.parse(next.id), greaterThan(2));
    await database.close();
    final reopened = await AppPreferences.load(database: database);
    expect(reopened.themeMode, ThemeMode.dark);
    expect(reopened.reconciliationPending, isTrue);
    expect(await todos.getTodos(), hasLength(3));
    reopened.dispose();
  });

  test(
    'empty backup preserves light and Thai defaults and replaces existing rows',
    () async {
      final empty = await backups.create(appVersion: '1.0.0');
      expect(empty.backup.appSettings, {
        'themeMode': 'light',
        'languageCode': 'th',
      });
      await sample();
      await backups.restore(empty.backup);
      await preferences.reload();
      expect(await todos.getTodos(), isEmpty);
      expect(preferences.themeMode, ThemeMode.light);
      expect(preferences.locale, const Locale('th'));
      expect(preferences.dailySummaryEnabled, isFalse);
      expect(preferences.reminderMinutes, 540);
    },
  );

  for (final failureStage in RestoreStage.values) {
    test(
      'failure at $failureStage rolls back tasks/settings/runtime and survives reopen',
      () async {
        final empty = await backups.create(appVersion: '1.0.0');
        await sample();
        final before = (await todos.getTodos()).map((t) => t.toJson()).toList();
        final ledger = preferences.summaryLedger;
        await expectLater(
          backups.restore(
            empty.backup,
            onStage: (stage) {
              if (stage == failureStage) {
                throw StateError('injected transaction failure');
              }
            },
          ),
          throwsStateError,
        );
        await database.close();
        final reopened = await AppPreferences.load(database: database);
        expect(
          (await todos.getTodos()).map((t) => t.toJson()).toList(),
          before,
        );
        expect(reopened.themeMode, ThemeMode.dark);
        expect(reopened.locale, const Locale('th'));
        expect(reopened.reminderMinutes, 600);
        expect(reopened.summaryLedger, ledger);
        expect(reopened.reconciliationPending, isFalse);
        reopened.dispose();
      },
    );
  }

  test(
    'validation rejects malformed or unsupported input without changing data',
    () async {
      final snapshot = await sample();
      final edits = <void Function(Map<String, dynamic>)>[
        (m) => m.remove('createdAt'),
        (m) => m['format'] = 'another_app',
        (m) => m['createdAt'] = '2026-02-30T12:00:00Z',
        (m) => m['payload']['todos'][0]['completed'] = 1,
        (m) => m['payload']['todos'][0]['id'] = 0,
        (m) => m['payload']['todos'].add(m['payload']['todos'][0]),
        (m) => m['payload']['todos'][0]['priority'] = 'critical',
        (m) => m['payload']['todos'][0]['created_at'] = null,
        (m) => m['payload']['todos'][0]['due_date'] = '2026-13-01T00:00:00',
        (m) => m['payload']['appSettings']['themeMode'] = 'unknown',
        (m) => m['payload']['appSettings']['languageCode'] = 'fr',
        (m) => m['payload']['notificationSettings']['dailySummaryEnabled'] =
            'true',
        (m) => m['payload']['notificationSettings']['reminderMinutes'] = 1440,
        (m) => m['payload']['categories'] = [],
      ];
      final invalid = [
        Uint8List.fromList([0xff]),
        Uint8List.fromList(utf8.encode('{')),
        changeBackup(
          snapshot.bytes,
          (m) => m['appVersion'] = 'tampered',
          checksum: false,
        ),
        ...edits.map((edit) => changeBackup(snapshot.bytes, edit)),
      ];
      for (final bytes in invalid) {
        expect(
          () => codec.decode(bytes),
          throwsA(
            isA<BackupException>().having(
              (e) => e.failure,
              'failure',
              BackupFailure.invalid,
            ),
          ),
        );
      }
      for (final key in ['backupVersion', 'databaseVersion']) {
        expect(
          () => codec.decode(changeBackup(snapshot.bytes, (m) => m[key] = 99)),
          throwsA(
            isA<BackupException>().having(
              (e) => e.failure,
              'failure',
              BackupFailure.unsupported,
            ),
          ),
        );
      }
      expect(await todos.getTodos(), hasLength(2));
      expect(preferences.themeMode, ThemeMode.dark);
    },
  );

  test('decoded package cannot be mutated after preview', () async {
    final snapshot = await sample();
    expect(() => snapshot.backup.todos.clear(), throwsUnsupportedError);
    expect(
      () => snapshot.backup.todos.first['title'] = 'changed',
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.backup.appSettings['themeMode'] = 'light',
      throwsUnsupportedError,
    );
  });

  test(
    'snapshot waits for in-flight writes and gate recovers after an error',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final write = database.gate.run(() async {
        started.complete();
        await release.future;
        await todos.createTodo('Queued', '');
        await preferences.saveThemeMode(ThemeMode.dark);
      });
      await started.future;
      var complete = false;
      final snapshot = backups.create(appVersion: '1.0.0').then((v) {
        complete = true;
        return v;
      });
      await Future<void>.delayed(Duration.zero);
      expect(complete, isFalse);
      release.complete();
      await write;
      final result = await snapshot;
      expect(result.backup.taskCount, 1);
      expect(result.backup.appSettings['themeMode'], 'dark');
      await expectLater(
        database.gate.run<void>(() async => throw StateError('failure')),
        throwsStateError,
      );
      expect(await backups.taskCount(), 1);
    },
  );
}
