import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:longdow_todo_list/app/app.dart';
import 'package:longdow_todo_list/app/app_preferences.dart';
import 'package:longdow_todo_list/app/app_shell.dart';
import 'package:longdow_todo_list/core/database/app_database.dart';
import 'package:longdow_todo_list/features/notifications/models/daily_summary.dart';
import 'package:longdow_todo_list/features/notifications/services/notification_service.dart';
import 'package:longdow_todo_list/features/notifications/widgets/daily_summary_host.dart';
import 'package:longdow_todo_list/features/todo/providers/todo_provider.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Real permissions/scheduling with a separate notification ID/channel namespace
/// and temporary SQLite database. Existing tasks and reminders are preserved.
class _SmokeNotifications implements NotificationService {
  final _native = LocalNotificationService();
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _offset = 500000000;
  @override
  bool get supported => _native.supported;
  @override
  Future<void> initialize() => _native.initialize();
  @override
  Future<tz.Location> getLocation() => _native.getLocation();
  @override
  Future<bool> requestPermission() => _native.requestPermission();
  @override
  Future<bool> hasPermission() => _native.hasPermission();
  @override
  Future<List<int>> pendingIds() async => [
    for (final request in await _plugin.pendingNotificationRequests())
      if (DailySummaryRequest.ownsId(request.id - _offset))
        request.id - _offset,
  ];
  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id + _offset);
  @override
  Future<void> schedule(
    DailySummaryRequest request,
    String title,
    String body,
  ) => _plugin.zonedSchedule(
    id: request.id + _offset,
    title: title,
    body: body,
    scheduledDate: request.date,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'onboarding_smoke',
        'Onboarding smoke test',
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
  @override
  Future<void> showTest(String title, String body) =>
      throw UnsupportedError('Unused');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native onboarding, real schedule, first task and relaunch', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'onboarding_native_',
    );
    final screenshots = Directory(
      '${Directory.systemTemp.path}/onboarding_previews',
    );
    await screenshots.create(recursive: true);
    final database = AppDatabase(path: '${directory.path}/tasks.db');
    final prefs = await AppPreferences.load(database: database);
    final os = _SmokeNotifications();
    final previewKey = GlobalKey();
    Future<void> tap(String label) async {
      debugPrint('ONBOARDING_NATIVE: tapping $label');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final finder = find.text(label);
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          150,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> screenshot(String name) async {
      await tester.pumpAndSettle();
      final boundary =
          previewKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${screenshots.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      debugPrint('ONBOARDING_SCREENSHOT: ${screenshots.path}/$name.png');
    }

    Future<void> mount() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            notificationServiceProvider.overrideWithValue(os),
          ],
          child: RepaintBoundary(
            key: previewKey,
            child: TodoApp(preferences: prefs),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    try {
      // Real legacy preferences can exist on the device; isolate this session.
      await prefs.restartOnboarding();
      await prefs.saveLocale(const Locale('th'));
      await prefs.saveThemeMode(ThemeMode.system);
      await prefs.saveDailySummaryEnabled(false);
      if (const bool.fromEnvironment('PREGRANTED_NOTIFICATIONS')) {
        await os.initialize();
        debugPrint('READY_FOR_NOTIFICATION_GRANT');
        for (
          var attempt = 0;
          attempt < 60 && !await os.hasPermission();
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        expect(await os.hasPermission(), isTrue);
      }
      await mount();
      await screenshot('welcome');
      await tap('เริ่มต้นใช้งาน');
      await tap('มืด');
      await screenshot('personalize_dark');
      await tap('สว่าง');
      await tap('ถัดไป');
      await screenshot('summary');
      // If permission is not granted, an operator must accept the OS dialog.
      await tap('เปิดสรุปงานประจำวัน');
      expect(find.text('เปิดสรุปงานประจำวันแล้ว'), findsOneWidget);
      expect(await os.pendingIds(), hasLength(30));
      await tap('ถัดไป');
      await screenshot('first_task');
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_task_title')),
        'อ่านหนังสือ',
      );
      await tap('เพิ่มงานแรก');
      expect(find.text('เพิ่มงานแรกแล้ว!'), findsOneWidget);
      expect(
        (await TodoService(database).getTodos()).single.title,
        'อ่านหนังสือ',
      );
      await screenshot('success');
      await tap('เริ่มใช้งานแอป');
      expect(find.byType(AppShell), findsOneWidget);
      await screenshot('home');
      await tester.pumpWidget(const SizedBox());
      await prefs.reload();
      await mount();
      expect(find.byType(AppShell), findsOneWidget);
      expect(prefs.onboardingCompleted, isTrue);
      debugPrint('ONBOARDING_NATIVE: passed');
    } finally {
      await tester.pumpWidget(const SizedBox());
      await database.gate.run(() async {});
      for (final id in await os.pendingIds()) {
        await os.cancel(id);
      }
      prefs.dispose();
      await database.close();
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
