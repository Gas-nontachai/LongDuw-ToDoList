import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/app.dart';
import 'package:longdow_todo_list/app/app_shell.dart';
import 'package:longdow_todo_list/features/backup/services/backup_file_gateway.dart';
import 'package:longdow_todo_list/features/backup/services/backup_service.dart';
import 'package:longdow_todo_list/features/notifications/widgets/daily_summary_host.dart';
import 'package:longdow_todo_list/features/todo/providers/todo_provider.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';
import 'package:longdow_todo_list/shared/widgets/liquid_glass_bottom_navigation.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'support/fake_backup_files.dart';
import 'support/fake_notifications.dart';
import 'support/test_preferences.dart';

void main() {
  late TestPreferences fixture;
  setUp(() {
    fixture = TestPreferences();
    tz_data.initializeTimeZones();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => fixture.close());

  testWidgets(
    'restore updates providers, theme, language, clears search and opens Home',
    (tester) async {
      final preferences = await fixture.load();
      final todos = TodoService(fixture.database);
      final restored = await todos.createTodo('งานที่กู้คืน', 'รายละเอียด');
      await preferences.saveThemeMode(ThemeMode.dark);
      await preferences.saveLocale(const Locale('th'));
      await preferences.saveDailySummaryEnabled(true);
      final snapshot = await BackupService(preferences: preferences)
          .create(appVersion: '1.0.0');
      await todos.deleteTodo(restored.id);
      await todos.createTodo('Current', '');
      await preferences.saveThemeMode(ThemeMode.light);
      await preferences.saveLocale(const Locale('en'));
      final os = FakeNotifications();
      final files = FakeBackupFiles()
        ..selected = PickedBackupFile('selected.todo', snapshot.bytes);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(fixture.database),
            notificationServiceProvider.overrideWithValue(os),
            backupFileGatewayProvider.overrideWithValue(files),
          ],
          child: TodoApp(preferences: preferences),
        ),
      );
      await tester.pumpAndSettle();
      void select(int index) => tester
          .widget<LiquidGlassBottomNavigation>(
            find.byType(LiquidGlassBottomNavigation),
          )
          .onSelected(index);
      select(1);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hidden search');
      await tester.pump(const Duration(milliseconds: 400));
      select(3);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Restore backup'));
      await tester.drag(find.byType(ListView).last, const Offset(0, -180));
      await tester.pumpAndSettle();
      // Exercise the actual compute-based validator in its real async zone.
      await tester.tap(find.text('Restore backup'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace & restore'));
      await tester.pumpAndSettle();
      expect(find.text('กู้คืนข้อมูลสำเร็จ'), findsOneWidget);
      expect(preferences.themeMode, ThemeMode.dark);
      expect(preferences.locale, const Locale('th'));
      expect(os.titles.values.toSet(), {'สรุปงานรายวัน'});
      expect(os.permissionRequests, 0);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell, skipOffstage: false)),
      );
      expect(
        container.read(todoProvider).requireValue.single.title,
        'งานที่กู้คืน',
      );
      await tester.tap(find.text('ไปหน้าหลัก'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LiquidGlassBottomNavigation>(
              find.byType(LiquidGlassBottomNavigation),
            )
            .selectedIndex,
        0,
      );
      select(1);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('งานที่กู้คืน'), findsWidgets);
      expect(
        Theme.of(tester.element(find.byType(AppShell, skipOffstage: false)))
            .brightness,
        Brightness.dark,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('unsupported platforms hide Data & Backup', (tester) async {
    final preferences = await fixture.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(fixture.database),
          backupFileGatewayProvider.overrideWithValue(
            FakeBackupFiles()..supported = false,
          ),
          notificationServiceProvider.overrideWithValue(
            FakeNotifications()..supported = false,
          ),
        ],
        child: TodoApp(preferences: preferences),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<LiquidGlassBottomNavigation>(
          find.byType(LiquidGlassBottomNavigation),
        )
        .onSelected(3);
    await tester.pumpAndSettle();
    expect(find.text('Data & Backup'), findsNothing);
    expect(find.text('Backup data'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
