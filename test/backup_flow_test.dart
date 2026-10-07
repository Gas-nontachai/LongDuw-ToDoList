import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/app_preferences.dart';
import 'package:longdow_todo_list/app/theme.dart';
import 'package:longdow_todo_list/features/backup/models/backup_package.dart';
import 'package:longdow_todo_list/features/backup/providers/backup_controller.dart';
import 'package:longdow_todo_list/features/backup/services/backup_file_gateway.dart';
import 'package:longdow_todo_list/features/backup/services/backup_service.dart';
import 'package:longdow_todo_list/features/backup/widgets/backup_flow.dart';
import 'package:longdow_todo_list/features/notifications/providers/daily_summary_controller.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';
import 'package:longdow_todo_list/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'support/fake_backup_files.dart';
import 'support/fake_notifications.dart';
import 'support/test_preferences.dart';

void main() {
  late TestPreferences fixture;
  late FakeBackupFiles files;
  late FakeNotifications os;
  late DailySummaryController notifications;
  late AppPreferences preferences;
  late TodoService todos;
  late BackupService service;
  late BackupController controller;
  var reloads = 0;
  var home = false;
  var failReload = false;
  setUp(() {
    fixture = TestPreferences();
    files = FakeBackupFiles();
    os = FakeNotifications();
    reloads = 0;
    home = false;
    failReload = false;
    tz_data.initializeTimeZones();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() async {
    notifications.dispose();
    await fixture.close();
  });

  Future<void> prepare() async {
    preferences = await fixture.load();
    todos = TodoService(fixture.database);
    await todos.createTodo('Current task', '');
    service = BackupService(preferences: preferences);
    notifications = DailySummaryController(
      preferences: preferences,
      notifications: os,
      loadTodos: todos.getTodos,
      now: () => DateTime(2026, 10, 6, 8),
    );
    controller = BackupController(
      service: service,
      files: files,
      appVersion: () async => '1.0.0',
      notifications: notifications,
      reloadApp: () async {
        if (failReload) throw StateError('reload failed');
        reloads++;
      },
      now: () => DateTime(2026, 10, 6, 10),
      decodeBackup: (bytes) async => const BackupCodec().decode(bytes),
    );
  }

  Future<void> open(
    WidgetTester tester, {
    bool restore = false,
    String language = 'en',
    bool dark = false,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? appDarkTheme : appTheme,
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showBackupFlow(
                  context,
                  controller,
                  restore: restore,
                  onGoHome: () => home = true,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('backup summary, native save completion and Done', (
    tester,
  ) async {
    await prepare();
    await open(tester);
    expect(find.text('1 task'), findsOneWidget);
    expect(find.text('todo_backup_2026-10-06.todo'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Create backup'));
    await tester.pumpAndSettle();
    expect(files.saves, 1);
    expect(files.savedName, 'todo_backup_2026-10-06.todo');
    expect(const BackupCodec().decode(files.savedBytes!).taskCount, 1);
    expect(find.text('Backup created'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(home, isFalse);
  });

  testWidgets('cancel summary or native save never claims backup success', (
    tester,
  ) async {
    await prepare();
    await open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(files.saves, 0);
    expect(find.text('Backup created'), findsNothing);
    await prepare();
    files.saveResult = false;
    await open(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Create backup'));
    await tester.pumpAndSettle();
    expect(find.text('Backup created'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('save failure exposes retry; no false success', (tester) async {
    await prepare();
    files.failSave = true;
    await open(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Create backup'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to create backup'), findsOneWidget);
    files.failSave = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Backup created'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  });

  testWidgets('picker cancellation and corrupted files keep current data', (
    tester,
  ) async {
    await prepare();
    await open(tester, restore: true);
    expect(find.text('Open'), findsOneWidget);
    expect((await todos.getTodos()).single.title, 'Current task');
    await prepare();
    files.selected = PickedBackupFile(
      'broken.todo',
      Uint8List.fromList([0xff]),
    );
    await open(tester, restore: true);
    expect(find.text('Unable to restore backup'), findsOneWidget);
    expect(find.textContaining('has not been changed'), findsOneWidget);
    await tester.tap(find.text('Choose another file'));
    await tester.pumpAndSettle();
    expect((await todos.getTodos()), hasLength(2));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'both confirmations precede replace; processing blocks Back and duplicate taps',
    (tester) async {
      await prepare();
      await preferences.saveDailySummaryEnabled(true);
      final snapshot = await service.create(appVersion: '1.0.0');
      files.selected = PickedBackupFile('selected.todo', snapshot.bytes);
      await todos.createTodo('Must disappear', '');
      os.allowed = false;
      await open(tester, restore: true);
      expect(find.textContaining('replace all current data'), findsOneWidget);
      expect(await todos.getTodos(), hasLength(2));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Replace current data?'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Replace & restore'),
      );
      expect(
        button.style!.backgroundColor!.resolve({}),
        appTheme.colorScheme.error,
      );
      // Hold a real write ahead of restore to inspect the protected loading state.
      final release = Completer<void>();
      final started = Completer<void>();
      final write = fixture.database.gate.run(() async {
        started.complete();
        await release.future;
      });
      await started.future;
      await tester.tap(find.text('Replace & restore'));
      await tester.pump();
      button.onPressed!();
      expect(controller.step, BackupStep.restoring);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Restoring backup…'), findsOneWidget);
      release.complete();
      await write;
      await tester.pumpAndSettle();
      expect(find.text('Restore complete'), findsOneWidget);
      expect(find.textContaining('Notifications are blocked'), findsOneWidget);
      expect(os.permissionRequests, 0);
      expect(await todos.getTodos(), hasLength(1));
      expect(preferences.dailySummaryEnabled, isTrue);
      expect(reloads, 1);
      os.allowed = true;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(os.permissionRequests, 0);
      expect(os.scheduled, hasLength(30));
      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();
      expect(home, isTrue);
    },
  );

  testWidgets('cancel preview and final confirmation do not replace anything', (
    tester,
  ) async {
    await prepare();
    final snapshot = await service.create(appVersion: '1.0.0');
    files.selected = PickedBackupFile('selected.todo', snapshot.bytes);
    await todos.createTodo('Keep me', '');
    await open(tester, restore: true);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await todos.getTodos(), hasLength(2));
    await prepare();
    await open(tester, restore: true);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await todos.getTodos(), hasLength(3));
    expect(reloads, 0);
  });

  testWidgets(
    'post-commit reload failure stays complete and retries without replacing again',
    (tester) async {
      await prepare();
      final snapshot = await service.create(appVersion: '1.0.0');
      files.selected = PickedBackupFile('selected.todo', snapshot.bytes);
      await todos.createTodo('Old data', '');
      failReload = true;
      await open(tester, restore: true);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace & restore'));
      await tester.pumpAndSettle();
      expect(find.text('Restore complete'), findsOneWidget);
      expect(find.text('Restore failed'), findsNothing);
      expect(await todos.getTodos(), hasLength(1));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Go to Home'),
            )
            .onPressed,
        isNull,
      );
      failReload = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();
      expect(home, isTrue);
    },
  );

  testWidgets(
    'scheduling failure keeps restored data and retries notifications',
    (tester) async {
      await prepare();
      await preferences.saveDailySummaryEnabled(true);
      final snapshot = await service.create(appVersion: '1.0.0');
      files.selected = PickedBackupFile('selected.todo', snapshot.bytes);
      await todos.createTodo('Must disappear', '');
      os.failAfter = 2;
      await open(tester, restore: true);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace & restore'));
      await tester.pumpAndSettle();
      expect(find.text('Restore complete'), findsOneWidget);
      expect(await todos.getTodos(), hasLength(1));
      expect(preferences.reconciliationPending, isTrue);
      expect(os.scheduled, hasLength(2));
      expect(os.cancelled, isNot(contains(42)));
      expect(os.permissionRequests, 0);
      os.failAfter = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(os.scheduled, hasLength(30));
      expect(preferences.reconciliationPending, isFalse);
      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Thai dark-mode summary fits a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await prepare();
    await open(tester, language: 'th', dark: true, scale: 1.5);
    expect(find.text('สร้างข้อมูลสำรอง'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
  });
}
