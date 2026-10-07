import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/app.dart';
import 'package:longdow_todo_list/app/app_preferences.dart';
import 'package:longdow_todo_list/app/app_shell.dart';
import 'package:longdow_todo_list/features/notifications/widgets/daily_summary_host.dart';
import 'package:longdow_todo_list/features/onboarding/screens/onboarding_screen.dart';
import 'package:longdow_todo_list/features/todo/providers/todo_provider.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';
import 'package:longdow_todo_list/shared/widgets/liquid_glass_bottom_navigation.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tz_data;

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

  Future<void> pumpApp(
    WidgetTester tester,
    AppPreferences prefs,
    FakeNotifications os,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(fixture.database),
          notificationServiceProvider.overrideWithValue(os),
        ],
        child: TodoApp(preferences: prefs),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
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

  Future<AppPreferences> prefsAt(int step) async {
    final prefs = await fixture.load(completeOnboarding: false);
    await prefs.saveLocale(const Locale('en'));
    await prefs.saveOnboardingStep(step);
    return prefs;
  }

  testWidgets('welcome skip enters Home, stays completed, never prompts', (
    tester,
  ) async {
    final prefs = await prefsAt(0);
    final os = FakeNotifications()..permissionGranted = false;
    await pumpApp(tester, prefs, os);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tap(tester, 'Skip introduction');
    expect(find.byType(AppShell), findsOneWidget);
    expect(prefs.onboardingCompleted, isTrue);
    expect(os.permissionRequests, 0);
    expect(os.scheduled, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, await fixture.load(completeOnboarding: false), os);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets(
    'language and theme preview persist, checkpoint survives relaunch',
    (tester) async {
      final prefs = await prefsAt(0);
      final os = FakeNotifications();
      await pumpApp(tester, prefs, os);
      await tap(tester, 'Get started');
      await tap(tester, 'Dark');
      expect(prefs.themeMode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(OnboardingScreen))).brightness,
        Brightness.dark,
      );
      await tap(tester, 'ไทย');
      expect(find.text('ปรับแอปให้เป็นของคุณ'), findsOneWidget);
      await tap(tester, 'ตามระบบ');
      expect(prefs.themeMode, ThemeMode.system);
      await tap(tester, 'English');
      await tap(tester, 'Next');
      expect(prefs.onboardingStep, 2);
      await tester.pumpWidget(const SizedBox());
      final reopened = await fixture.load(completeOnboarding: false);
      await pumpApp(tester, reopened, os);
      expect(find.text('Daily summary'), findsOneWidget);
      expect(os.permissionRequests, 0);
      await tap(tester, 'Not now');
      expect(find.text('Create your first task'), findsOneWidget);
      await tap(tester, 'Skip');
      expect(find.byType(AppShell), findsOneWidget);
      expect(await TodoService(fixture.database).getTodos(), isEmpty);
      expect(os.permissionRequests, 0);
    },
  );

  for (final allowed in [true, false]) {
    testWidgets(
      'loading hides all results until permission and scheduling finish ($allowed)',
      (tester) async {
        final prefs = await prefsAt(2);
        final permission = Completer<bool>();
        final scheduling = Completer<void>();
        final os = FakeNotifications()
          ..permissionGranted = false
          ..permissionGate = permission
          ..schedulingGate = scheduling;
        await pumpApp(tester, prefs, os);
        final button = find.text('Enable daily summary');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        void expectWaiting() {
          expect(find.text('Preparing notifications…'), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('Notifications are not enabled'), findsNothing);
          expect(
            find.text('Could not update reminders. Please retry.'),
            findsNothing,
          );
          expect(find.text('Daily summary is enabled'), findsNothing);
          expect(find.text('Next'), findsNothing);
          expect(find.text('Retry'), findsNothing);
        }

        expect(os.permissionRequests, 1);
        expectWaiting();
        // Returning from the OS dialog can enqueue lifecycle reconciliation.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 100));
        expectWaiting();
        permission.complete(allowed);
        await tester.pump(const Duration(milliseconds: 100));
        if (allowed) {
          // A permission grant is not success until scheduling also completes.
          expectWaiting();
        }
        scheduling.complete();
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Preparing notifications…'), findsNothing);
        expect(
          find.text(
            allowed
                ? 'Daily summary is enabled'
                : 'Notifications are not enabled',
          ),
          findsOneWidget,
        );
        expect(os.permissionRequests, 1);
        expect(find.text('Next'), findsOneWidget);
      },
    );
  }

  for (final outcome in [
    'allowed',
    'existing',
    'denied',
    'failed',
    'unsupported',
  ]) {
    testWidgets('notification outcome: $outcome, user can always continue', (
      tester,
    ) async {
      final prefs = await prefsAt(2);
      final os = FakeNotifications()
        ..permissionGranted = outcome == 'existing'
        ..allowed = outcome != 'denied'
        ..supported = outcome != 'unsupported'
        ..failAfter = outcome == 'failed' ? 0 : null;
      await pumpApp(tester, prefs, os);
      expect(os.permissionRequests, 0);
      if (outcome != 'unsupported') {
        await tap(tester, 'Enable daily summary');
        expect(os.permissionRequests, outcome == 'existing' ? 0 : 1);
        if (outcome == 'allowed' || outcome == 'existing') {
          expect(find.text('Daily summary is enabled'), findsOneWidget);
          expect(os.scheduled, hasLength(30));
        } else if (outcome == 'denied') {
          expect(find.text('Notifications are not enabled'), findsOneWidget);
          expect(prefs.dailySummaryEnabled, isFalse);
          expect(find.text('Retry'), findsNothing);
          // Background/resume must not open another system prompt.
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
          expect(os.permissionRequests, 1);
          expect(find.text('Notifications are not enabled'), findsOneWidget);
        } else {
          expect(find.text('Daily summary is enabled'), findsNothing);
          expect(find.text('Retry'), findsOneWidget);
          os.failAfter = null;
          await tap(tester, 'Retry');
          expect(find.text('Daily summary is enabled'), findsOneWidget);
          expect(os.permissionRequests, 1);
        }
      } else {
        expect(find.text('Available on Android and iOS.'), findsOneWidget);
      }
      await tap(tester, 'Next');
      expect(find.text('Create your first task'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'first task validates, preserves back navigation draft, saves once and refreshes Home',
    (tester) async {
      final prefs = await prefsAt(3);
      final os = FakeNotifications();
      await pumpApp(tester, prefs, os);
      await tap(tester, 'Add first task');
      expect(find.text('Enter a title'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_task_title')),
        '  Read a book  ',
      );
      await tester.pumpAndSettle();
      expect(find.text('Enter a title'), findsNothing);
      final detailsField = find.widgetWithText(TextFormField, 'Details');
      await tester.enterText(detailsField, 'One chapter');
      await tester.pumpAndSettle();
      await tap(tester, 'Priority');
      await tap(tester, 'High');
      final clearDate = find.byTooltip('Clear due date');
      await tester.ensureVisible(clearDate);
      await tester.pumpAndSettle();
      await tester.tap(clearDate);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 1200),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tap(tester, 'Not now');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('onboarding_task_title')),
            )
            .controller!
            .text,
        '  Read a book  ',
      );
      await tester.ensureVisible(find.text('Add first task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add first task'));
      await tester.tap(find.text('Add first task'));
      await tester.pumpAndSettle();
      expect(find.text('Your first task is added!'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      final todos = await TodoService(fixture.database).getTodos();
      expect(todos, hasLength(1));
      expect(todos.single.title, 'Read a book');
      expect(todos.single.details, 'One chapter');
      expect(todos.single.priority, 'high');
      expect(todos.single.dueDate, isNull);
      expect(todos.single.completed, isFalse);
      expect(prefs.onboardingCompleted, isTrue);
      await tap(tester, 'Start using the app');
      expect(find.text('1 task remaining'), findsNWidgets(2));
      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed task save keeps draft and retries without duplicates', (
    tester,
  ) async {
    final prefs = await prefsAt(3);
    final os = FakeNotifications();
    final db = await fixture.database.database;
    await db.execute(
      "CREATE TRIGGER reject_task BEFORE INSERT ON todos BEGIN SELECT RAISE(ABORT, 'injected task failure'); END",
    );
    await pumpApp(tester, prefs, os);
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_task_title')),
      'Read',
    );
    await tap(tester, 'Add first task');
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(prefs.onboardingCompleted, isFalse);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('onboarding_task_title')),
          )
          .controller!
          .text,
      'Read',
    );
    await db.execute('DROP TRIGGER reject_task');
    await tap(tester, 'Add first task');
    expect(find.text('Your first task is added!'), findsOneWidget);
    expect(await TodoService(fixture.database).getTodos(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Settings replay uses current choices and skips first task when tasks exist',
    (tester) async {
      final prefs = await fixture.load();
      await prefs.saveLocale(const Locale('en'));
      await prefs.saveThemeMode(ThemeMode.dark);
      await TodoService(fixture.database).createTodo('Existing', '');
      final os = FakeNotifications();
      await pumpApp(tester, prefs, os);
      tester
          .widget<LiquidGlassBottomNavigation>(
            find.byType(LiquidGlassBottomNavigation),
          )
          .onSelected(3);
      await tester.pumpAndSettle();
      await tap(tester, 'View introduction again');
      await tap(tester, 'Get started');
      expect(prefs.themeMode, ThemeMode.dark);
      await tap(tester, 'Next');
      await tap(tester, 'Not now');
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Create your first task'), findsNothing);
      expect(await TodoService(fixture.database).getTodos(), hasLength(1));
      expect(os.permissionRequests, 0);
    },
  );

  for (final language in ['th', 'en']) {
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      for (var step = 0; step < 4; step++) {
        testWidgets(
          'step $step fits small screen and large text ($language, $theme)',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(320, 568));
            tester.platformDispatcher.textScaleFactorTestValue = 2;
            addTearDown(() async {
              tester.platformDispatcher.clearTextScaleFactorTestValue();
              await tester.binding.setSurfaceSize(null);
            });
            final prefs = await fixture.load(completeOnboarding: false);
            await prefs.saveLocale(Locale(language));
            await prefs.saveThemeMode(theme);
            await prefs.saveOnboardingStep(step);
            await pumpApp(tester, prefs, FakeNotifications());
            await tester.drag(
              find.byType(SingleChildScrollView),
              const Offset(0, -1600),
            );
            await tester.pumpAndSettle();
            if (step == 3) {
              await tester.enterText(
                find.byKey(const ValueKey('onboarding_task_title')),
                'Read',
              );
              await tap(
                tester,
                language == 'th' ? 'เพิ่มงานแรก' : 'Add first task',
              );
              expect(
                find.text(
                  language == 'th'
                      ? 'เพิ่มงานแรกแล้ว!'
                      : 'Your first task is added!',
                ),
                findsOneWidget,
              );
            }
            expect(tester.takeException(), isNull);
            expect(find.byType(OnboardingScreen), findsOneWidget);
          },
        );
      }
    }
  }
}
