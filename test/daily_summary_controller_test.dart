import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:my_first_flutter_app/app/app_preferences.dart';
import 'package:my_first_flutter_app/core/config/dev_config.dart';
import 'package:my_first_flutter_app/features/notifications/providers/daily_summary_controller.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppPreferences prefs;
  late FakeNotifications notifications;
  late DailySummaryController controller;
  late DateTime now;
  late List<Todo> todos;
  var loads = 0;

  setUp(() async {
    tz_data.initializeTimeZones();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = await AppPreferences.load();
    notifications = FakeNotifications();
    now = tz.TZDateTime(tz.getLocation('Asia/Bangkok'), 2026, 10, 5, 8);
    todos = [];
    loads = 0;
    controller = DailySummaryController(
      preferences: prefs,
      notifications: notifications,
      now: () => now,
      loadTodos: () async {
        loads++;
        return todos;
      },
    );
  });
  tearDown(() => controller.dispose());

  test('OFF at first launch never prompts or loads Todo data', () async {
    await controller.refresh();
    expect(controller.enabled, isFalse);
    expect(controller.reminderMinutes, 540);
    expect(notifications.initializations, 0);
    expect(notifications.permissionRequests, 0);
    expect(loads, 0);
  });

  test(
    'denied permission keeps feature OFF and exposes actionable state',
    () async {
      notifications.allowed = false;
      await controller.setEnabled(true);
      expect(controller.enabled, isFalse);
      expect(controller.issue, DailySummaryIssue.permissionDenied);
      expect(notifications.scheduled, isEmpty);
      notifications.allowed = true;
      await controller.setEnabled(true);
      expect(controller.enabled, isTrue);
      expect(controller.issue, isNull);
      expect(notifications.scheduled, hasLength(30));
    },
  );

  test(
    'uses all persisted tasks and all three Thai message variants',
    () async {
      await prefs.saveLocale(const Locale('th'));
      todos = [
        Todo(
          id: '1',
          title: '',
          details: '',
          completed: false,
          dueDate: DateTime(2026, 10, 5),
        ),
        Todo(
          id: '2',
          title: '',
          details: '',
          completed: false,
          dueDate: DateTime(2026, 10, 4),
        ),
        const Todo(id: '3', title: '', details: '', completed: false),
      ];
      await controller.setEnabled(true);
      expect(
        notifications.bodies[120261005],
        'วันนี้มี 1 งาน · เลยกำหนด 1 งาน',
      );
      expect(
        notifications.bodies[120261006],
        'วันนี้ไม่มีงาน · เลยกำหนด 2 งาน',
      );
      todos = todos.map((t) => t.copyWith(completed: true)).toList();
      await controller.refresh();
      expect(notifications.bodies.values.toSet(), {
        'วันนี้ไม่มีงาน 🎉 วางแผนงานถัดไปกันไหม',
      });
      expect(notifications.cancelled, isNot(contains(42)));
      expect(notifications.permissionRequests, 1);
    },
  );

  test('restarts and moving time later cannot schedule today twice', () async {
    await controller.setEnabled(true);
    now = tz.TZDateTime(tz.getLocation('Asia/Bangkok'), 2026, 10, 5, 10);
    controller.dispose();
    prefs = await AppPreferences.load();
    controller = DailySummaryController(
      preferences: prefs,
      notifications: notifications,
      now: () => now,
      loadTodos: () async => todos,
    );
    await controller.setReminderMinutes(11 * 60);
    expect(notifications.scheduled.containsKey(120261005), isFalse);
    expect(notifications.scheduled, hasLength(30));
    expect(prefs.summaryConsumedDay, 20261005);
    await controller.setEnabled(false);
    await controller.setEnabled(true);
    expect(notifications.scheduled.containsKey(120261005), isFalse);
  });

  test(
    'OFF cancels only owned pending alerts; time remains persisted',
    () async {
      await controller.setReminderMinutes(10 * 60 + 15);
      await controller.setEnabled(true);
      await controller.setEnabled(false);
      expect(notifications.scheduled, isEmpty);
      expect(notifications.cancelled, hasLength(30));
      expect(notifications.cancelled, isNot(contains(42)));
      final restored = await AppPreferences.load();
      expect(restored.dailySummaryEnabled, isFalse);
      expect(restored.reminderMinutes, 615);
      expect(restored.summaryLedger, isEmpty);
    },
  );

  test(
    'partial scheduling failure is recoverable and queue keeps working',
    () async {
      notifications.failAfter = 2;
      await controller.setEnabled(true);
      expect(controller.issue, DailySummaryIssue.failed);
      expect(prefs.summaryLedger, hasLength(2));
      notifications.failAfter = null;
      await controller.refresh();
      expect(controller.issue, isNull);
      expect(notifications.scheduled, hasLength(30));
      await controller.setEnabled(false);
      expect(notifications.scheduled, isEmpty);
    },
  );

  test(
    'revoked permission cancels reminders without prompting on resume',
    () async {
      await controller.setEnabled(true);
      notifications.allowed = false;
      await controller.refresh();
      expect(controller.issue, DailySummaryIssue.permissionDenied);
      expect(notifications.scheduled, isEmpty);
      expect(notifications.permissionRequests, 1);
    },
  );

  test('disable is serialized behind in-flight scheduling', () async {
    notifications.schedulingGate = Completer();
    final enable = controller.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    final disable = controller.setEnabled(false);
    notifications.schedulingGate!.complete();
    await Future.wait([enable, disable]);
    expect(controller.enabled, isFalse);
    expect(notifications.scheduled, isEmpty);
    expect(controller.busy, isFalse);
  });

  test('unsupported platforms cannot enable or request permission', () async {
    notifications.supported = false;
    await controller.setEnabled(true);
    expect(controller.enabled, isFalse);
    expect(notifications.permissionRequests, 0);
  });

  test('test notification is unavailable without the dev flag', () async {
    expect(
      await controller.testNotification(),
      TestNotificationResult.unavailable,
    );
    expect(notifications.previews, isEmpty);
    expect(notifications.permissionRequests, 0);
  }, skip: devToolsEnabled);

  test('preview uses sample counts without enabling, scheduling, or consuming a day', () async {
    await prefs.saveLocale(const Locale('th'));
    final ledger = {20261005: now.millisecondsSinceEpoch + 60000};
    await prefs.saveSummaryLedger(ledger);
    await prefs.saveSummaryConsumedDay(20261004);
    controller.issue = DailySummaryIssue.failed;
    expect(await controller.testNotification(), TestNotificationResult.shown);
    expect(notifications.previews.single, (
      title: 'สรุปงานรายวัน',
      body: 'วันนี้มี 4 งาน · เลยกำหนด 2 งาน',
    ));
    expect(controller.enabled, isFalse);
    expect(prefs.summaryLedger, ledger);
    expect(prefs.summaryConsumedDay, 20261004);
    expect(controller.issue, DailySummaryIssue.failed);
    expect(notifications.scheduled, isEmpty);
    expect(notifications.cancelled, isEmpty);
    expect(notifications.permissionRequests, 0);
    expect(loads, 0);
  }, skip: !devToolsEnabled);

  test(
    'denied preview permission shows nothing and does not enable summaries',
    () async {
      notifications.allowed = false;
      expect(
        await controller.testNotification(),
        TestNotificationResult.permissionDenied,
      );
      expect(notifications.permissionRequests, 1);
      expect(notifications.previews, isEmpty);
      expect(controller.enabled, isFalse);
      expect(controller.issue, isNull);
    },
    skip: !devToolsEnabled,
  );

  test('preview failure does not disturb a live summary schedule', () async {
    await controller.setEnabled(true);
    final ledger = prefs.summaryLedger;
    final ids = notifications.scheduled.keys.toSet();
    notifications.failPreview = true;
    expect(await controller.testNotification(), TestNotificationResult.failed);
    expect(controller.enabled, isTrue);
    expect(prefs.summaryLedger, ledger);
    expect(notifications.scheduled.keys.toSet(), ids);
    expect(controller.issue, isNull);
    expect(controller.busy, isFalse);
  }, skip: !devToolsEnabled);
}
