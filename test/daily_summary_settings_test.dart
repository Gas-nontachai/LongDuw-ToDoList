import 'support/test_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/app.dart';
import 'package:longdow_todo_list/core/config/dev_config.dart';
import 'package:longdow_todo_list/core/database/app_database.dart';
import 'package:longdow_todo_list/features/notifications/widgets/daily_summary_host.dart';
import 'package:longdow_todo_list/features/todo/models/todo.dart';
import 'package:longdow_todo_list/features/todo/providers/todo_provider.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';
import 'package:longdow_todo_list/shared/widgets/liquid_glass_bottom_navigation.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'support/fake_notifications.dart';

class MemoryTodos extends TodoService {
  MemoryTodos() : super(AppDatabase());
  List<Todo> todos = [
    Todo(
      id: '1',
      title: 'Today',
      details: 'Details',
      completed: false,
      dueDate: DateTime.now(),
    ),
  ];

  @override
  Future<List<Todo>> getTodos() async => [...todos];

  @override
  Future<Todo> updateTodo(Todo todo) async {
    todos = [for (final item in todos) item.id == todo.id ? todo : item];
    return todo;
  }
}

void main() {
  late TestPreferences preferencesFixture;
  tearDown(() => preferencesFixture.close());
  setUp(() async {
    preferencesFixture = TestPreferences();
    tz_data.initializeTimeZones();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'test notification is gated by dev flag and works while Daily Summary is OFF',
    (tester) async {
      final notifications = FakeNotifications();
      final prefs = (await preferencesFixture.load());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(notifications),
            todoServiceProvider.overrideWithValue(MemoryTodos()),
          ],
          child: TodoApp(preferences: prefs),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<LiquidGlassBottomNavigation>(
            find.byType(LiquidGlassBottomNavigation),
          )
          .onSelected(3);
      await tester.pumpAndSettle();
      if (devToolsEnabled) {
        expect(find.text('Test Notification'), findsOneWidget);
        await tester.tap(find.text('Test Notification'));
        await tester.pumpAndSettle();
        expect(notifications.previews.single, (
          title: 'Daily Summary',
          body: 'Today: 4 tasks · Overdue: 2',
        ));
        expect(
          find.text('Test notification sent. Check your notification center.'),
          findsOneWidget,
        );
        expect(prefs.dailySummaryEnabled, isFalse);
        expect(prefs.summaryLedger, isEmpty);
        expect(notifications.scheduled, isEmpty);
      } else {
        expect(find.text('Test Notification'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'denied test notification permission leaves switch OFF without an enable retry',
    (tester) async {
      final notifications = FakeNotifications()..allowed = false;
      final prefs = (await preferencesFixture.load());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(notifications),
            todoServiceProvider.overrideWithValue(MemoryTodos()),
          ],
          child: TodoApp(preferences: prefs),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<LiquidGlassBottomNavigation>(
            find.byType(LiquidGlassBottomNavigation),
          )
          .onSelected(3);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Notification'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Notifications are blocked'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(prefs.dailySummaryEnabled, isFalse);
      expect(notifications.previews, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !devToolsEnabled,
  );

  testWidgets('notification language follows the locale rendered by the app', (
    tester,
  ) async {
    final platform = tester.binding.platformDispatcher;
    platform.localeTestValue = const Locale('th');
    platform.localesTestValue = const [Locale('en')];
    addTearDown(platform.clearLocaleTestValue);
    addTearDown(platform.clearLocalesTestValue);
    final notifications = FakeNotifications();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(notifications),
          todoServiceProvider.overrideWithValue(MemoryTodos()),
        ],
        child: TodoApp(preferences: (await preferencesFixture.load())),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<LiquidGlassBottomNavigation>(
          find.byType(LiquidGlassBottomNavigation),
        )
        .onSelected(3);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Summary'));
    await tester.pumpAndSettle();
    expect(notifications.titles.values.toSet(), {'Daily Summary'});
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'settings persist time, request permission on enable, update after Todo changes',
    (tester) async {
      final prefs = (await preferencesFixture.load());
      final notifications = FakeNotifications();
      final todos = MemoryTodos();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(notifications),
            todoServiceProvider.overrideWithValue(todos),
          ],
          child: TodoApp(preferences: prefs),
        ),
      );
      await tester.pumpAndSettle();
      final navigation = tester.widget<LiquidGlassBottomNavigation>(
        find.byType(LiquidGlassBottomNavigation),
      );
      navigation.onSelected(3);
      await tester.pumpAndSettle();
      expect(notifications.permissionRequests, 0);
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Daily Summary'),
            )
            .value,
        isFalse,
      );

      await tester.tap(find.text('Reminder Time'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TimePickerDialog>(find.byType(TimePickerDialog))
            .initialTime,
        const TimeOfDay(hour: 9, minute: 0),
      );
      // Save the default time through the real picker path.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(((await preferencesFixture.load())).reminderMinutes, 540);

      await tester.tap(find.text('Daily Summary'));
      await tester.pumpAndSettle();
      expect(notifications.permissionRequests, 1);
      expect(notifications.scheduled, hasLength(30));
      expect(prefs.dailySummaryEnabled, isTrue);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DailySummaryHost)),
      );
      await container
          .read(todoProvider.notifier)
          .toggleTodo(todos.todos.single);
      await tester.pumpAndSettle();
      expect(notifications.bodies.values.toSet(), {
        'No tasks today 🎉 Shall we plan what’s next?',
      });

      // Changing the app language also rewrites notification text.
      await tester.tap(find.text('Change language'));
      await tester.pumpAndSettle();
      expect(notifications.bodies.values.toSet(), {
        'วันนี้ไม่มีงาน 🎉 วางแผนงานถัดไปกันไหม',
      });
      await tester.tap(find.text('สรุปงานรายวัน'));
      await tester.pumpAndSettle();
      expect(notifications.scheduled, isEmpty);
      expect(((await preferencesFixture.load())).dailySummaryEnabled, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('denied permission stays OFF and displays guidance', (
    tester,
  ) async {
    final notifications = FakeNotifications()..allowed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(notifications),
          todoServiceProvider.overrideWithValue(MemoryTodos()),
        ],
        child: TodoApp(preferences: (await preferencesFixture.load())),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<LiquidGlassBottomNavigation>(
          find.byType(LiquidGlassBottomNavigation),
        )
        .onSelected(3);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Summary'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Daily Summary'),
          )
          .value,
      isFalse,
    );
    expect(find.textContaining('Notifications are blocked'), findsOneWidget);
    expect(notifications.scheduled, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
