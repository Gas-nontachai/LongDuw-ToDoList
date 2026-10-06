import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:longdow_todo_list/app/app_preferences.dart';
import 'package:longdow_todo_list/features/backup/models/backup_package.dart';
import 'package:longdow_todo_list/features/backup/services/backup_file_gateway.dart';
import 'package:longdow_todo_list/features/backup/services/backup_service.dart';
import 'package:longdow_todo_list/core/database/app_database.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';

/// Run on Android/iOS with an operator controlling the native dialogs:
/// cancel first save, save second to local Files/Downloads, then pick that file.
/// Uses an isolated database and never restores over the app's normal data.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native save cancellation, save, pick and atomic round trip', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'todo_native_smoke_',
    );
    final database = AppDatabase(path: '${directory.path}/smoke.db');
    final preferences = await AppPreferences.load(database: database);
    final todos = TodoService(database);
    final service = BackupService(preferences: preferences);
    final files = NativeBackupFileGateway();
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Backup native smoke test'))),
        ),
      );
      final task = await todos.createTodo(
        'Native ไทย',
        'First line\nSecond line',
        priority: 'high',
        dueDate: DateTime(2026, 10, 7),
      );
      await todos.updateTodo(task.copyWith(completed: true));
      await preferences.saveThemeMode(ThemeMode.dark);
      await preferences.saveLocale(const Locale('th'));
      await preferences.saveDailySummaryEnabled(true);
      await preferences.saveReminderMinutes(615);
      final snapshot = await service.create(appVersion: '1.0.0');
      debugPrint('SMOKE: Cancel the first save dialog');
      expect(
        await files.save('todo_native_cancel.todo', snapshot.bytes),
        isFalse,
      );
      debugPrint('SMOKE: Save todo_native_smoke.todo to local Files/Downloads');
      expect(
        await files.save('todo_native_smoke.todo', snapshot.bytes),
        isTrue,
      );
      await todos.createTodo('Must disappear', '');
      await preferences.saveLocale(const Locale('en'));
      await preferences.saveThemeMode(ThemeMode.light);
      debugPrint('SMOKE: Pick todo_native_smoke.todo');
      final picked = await files.pick();
      expect(picked, isNotNull);
      expect(picked!.name, endsWith('.todo'));
      final validated = const BackupCodec().decode(picked.bytes);
      await service.restore(validated);
      await preferences.reload();
      expect((await todos.getTodos()).single.title, 'Native ไทย');
      expect((await todos.getTodos()).single.completed, isTrue);
      expect(preferences.themeMode, ThemeMode.dark);
      expect(preferences.locale, const Locale('th'));
      expect(preferences.dailySummaryEnabled, isTrue);
      expect(preferences.reminderMinutes, 615);
      await database.close();
      final reopened = await AppPreferences.load(database: database);
      expect(reopened.reconciliationPending, isTrue);
      expect((await todos.getTodos()).single.title, 'Native ไทย');
      reopened.dispose();
      debugPrint('SMOKE: Native backup/restore passed');
    } finally {
      preferences.dispose();
      await database.close();
      await directory.delete(recursive: true);
      await tester.pumpWidget(const SizedBox());
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
