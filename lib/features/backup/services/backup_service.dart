import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../app/app_preferences.dart';
import '../../../core/database/app_database.dart';
import '../models/backup_package.dart';

enum RestoreStage { replacingTasks, replacingSettings }

class BackupSnapshot {
  const BackupSnapshot(this.bytes, this.backup);
  final Uint8List bytes;
  final ValidatedBackup backup;
}

class BackupService {
  BackupService({required this.preferences, this.codec = const BackupCodec()});
  final AppPreferences preferences;
  final BackupCodec codec;
  AppDatabase get database => preferences.database;

  Future<int> taskCount() => database.gate.run(() async {
    final db = await database.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM todos');
    return rows.single['count'] as int;
  });

  Future<BackupSnapshot> create({
    required String appVersion,
    DateTime? now,
  }) => database.gate.run(() async {
    final db = await database.database;
    final bytes = await db.transaction((txn) async {
      final todos = [
        for (final row in await txn.query('todos', orderBy: 'id ASC'))
          {...row, 'completed': row['completed'] == 1},
      ];
      final settings = {
        for (final row in await txn.query('app_settings'))
          row['key'] as String: jsonDecode(row['value'] as String),
      };
      return codec.encode(
        createdAt: now ?? DateTime.now(),
        appVersion: appVersion,
        todos: todos,
        appSettings: {
          'themeMode':
              {
                'system',
                'light',
                'dark',
              }.contains(settings[AppPreferences.themeModeKey])
              ? settings[AppPreferences.themeModeKey]
              : 'system',
          'languageCode':
              {'en', 'th'}.contains(settings[AppPreferences.languageCodeKey])
              ? settings[AppPreferences.languageCodeKey]
              : null,
        },
        notificationSettings: {
          'dailySummaryEnabled':
              settings[AppPreferences.dailySummaryEnabledKey] == true,
          'reminderMinutes':
              settings[AppPreferences.reminderMinutesKey] is int &&
                  (settings[AppPreferences.reminderMinutesKey] as int) >= 0 &&
                  (settings[AppPreferences.reminderMinutesKey] as int) < 1440
              ? settings[AppPreferences.reminderMinutesKey]
              : 540,
        },
      );
    });
    return BackupSnapshot(bytes, codec.decode(bytes));
  });

  /// Progress callbacks run inside the transaction; thrown errors roll it back.
  /// Cache/UI/OS changes happen only after this method has committed.
  Future<void> restore(
    ValidatedBackup backup, {
    FutureOr<void> Function(RestoreStage)? onStage,
  }) => database.gate.run(() async {
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.delete('todos');
      await txn.delete(
        'sqlite_sequence',
        where: 'name = ?',
        whereArgs: ['todos'],
      );
      await onStage?.call(RestoreStage.replacingTasks);
      for (final row in backup.todos) {
        await txn.insert('todos', {
          ...row,
          'completed': row['completed'] == true ? 1 : 0,
        });
      }
      await txn.delete('app_settings');
      await onStage?.call(RestoreStage.replacingSettings);
      final settings = {
        AppPreferences.themeModeKey: backup.appSettings['themeMode'],
        AppPreferences.languageCodeKey: backup.appSettings['languageCode'],
        AppPreferences.dailySummaryEnabledKey:
            backup.notificationSettings['dailySummaryEnabled'],
        AppPreferences.reminderMinutesKey:
            backup.notificationSettings['reminderMinutes'],
      };
      for (final entry in settings.entries) {
        await txn.insert('app_settings', {
          'key': entry.key,
          'value': jsonEncode(entry.value),
        });
      }
      await txn.delete('notification_runtime');
      await txn.insert('notification_runtime', {
        'key': 'reconcile_pending',
        'value': 'true',
      });
    });
  });
}
