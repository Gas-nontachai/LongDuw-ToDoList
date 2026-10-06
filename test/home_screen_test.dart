import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/app_shell.dart';
import 'package:my_first_flutter_app/app/theme.dart';
import 'package:my_first_flutter_app/features/home/screens/home_screen.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/providers/todo_provider.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_detail.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_form.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_item.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';
import 'package:my_first_flutter_app/shared/widgets/app_error.dart';
import 'package:my_first_flutter_app/shared/widgets/app_loading.dart';
import 'package:my_first_flutter_app/shared/widgets/liquid_glass_bottom_navigation.dart';

class _Todos extends TodoNotifier {
  _Todos(this.items);
  final List<Todo> items;
  bool fail = false;
  Completer<void>? pending;
  int retries = 0;

  @override
  Future<List<Todo>> build() async => items;

  @override
  Future<void> refreshTodos() async {
    retries++;
    state = AsyncData(items);
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    final operations = ref.read(todoOperationProvider.notifier);
    operations.setBusy(todo.id, true);
    try {
      if (pending != null) await pending!.future;
      if (fail) throw StateError('save failed');
      state = AsyncData([
        for (final item in state.value!) item.id == todo.id ? todo : item,
      ]);
    } finally {
      operations.setBusy(todo.id, false);
    }
  }

  @override
  Future<void> deleteTodo(Todo todo) async {
    state = AsyncData([
      for (final item in state.value!)
        if (item.id != todo.id) item,
    ]);
  }
}

List<Todo> _tasks() {
  final now = DateTime.now();
  return [
    for (var i = 1; i <= 3; i++)
      Todo(
        id: '$i',
        title: 'Today task $i',
        details: 'Task details',
        completed: false,
        priority: 'high',
        dueDate: now,
      ),
    Todo(
      id: 'old',
      title: 'Overdue task',
      details: '',
      completed: false,
      dueDate: DateTime(now.year, now.month, now.day - 1),
    ),
    Todo(
      id: 'next',
      title: 'Tomorrow task',
      details: '',
      completed: false,
      dueDate: DateTime(now.year, now.month, now.day + 1),
    ),
    const Todo(id: 'done', title: 'Finished', details: '', completed: true),
    const Todo(id: 'none', title: 'No date', details: '', completed: false),
  ];
}

Future<void> _pumpHome(
  WidgetTester tester,
  _Todos todos, {
  String language = 'en',
  bool dark = false,
  double textScale = 1,
  VoidCallback? onOpenTasks,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [todoProvider.overrideWith(() => todos)],
      child: MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: dark ? appDarkTheme : appTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: HomeScreen(onOpenTasks: onOpenTasks ?? () {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;

void main() {
  testWidgets('preview, summaries and the single Tasks shortcut', (
    tester,
  ) async {
    var opened = 0;
    await _pumpHome(tester, _Todos(_tasks()), onOpenTasks: () => opened++);
    expect(find.byType(TodoItem), findsNWidgets(2));
    expect(find.text('Today task 1'), findsOneWidget);
    expect(find.text('Today task 2'), findsOneWidget);
    expect(find.text('Today task 3'), findsNothing);
    expect(find.text('Overdue task'), findsNothing);
    expect(find.text('Tomorrow task'), findsNothing);
    expect(find.text('No date'), findsNothing);
    expect(find.text('Finished'), findsNothing);
    expect(find.text('6 tasks remaining'), findsOneWidget);
    expect(find.text('3 due today · 1 overdue'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-view-all')));
    expect(opened, 1);
    await tester.scrollUntilVisible(find.byType(LinearProgressIndicator), 200);
    expect(find.text('1 of 7 completed'), findsOneWidget);
    expect(find.text('14%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1 / 7,
    );
  });

  testWidgets('completing a task refills preview and updates progress', (
    tester,
  ) async {
    final todos = _Todos(_tasks());
    await _pumpHome(tester, todos);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('Today task 1'), findsNothing);
    expect(find.text('Today task 2'), findsOneWidget);
    expect(find.text('Today task 3'), findsOneWidget);
    expect(find.text('5 tasks remaining'), findsOneWidget);
    expect(find.text('2 due today · 1 overdue'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(LinearProgressIndicator), 200);
    expect(find.text('2 of 7 completed'), findsOneWidget);
  });

  testWidgets('busy actions are disabled and failed saves keep the task', (
    tester,
  ) async {
    final todos = _Todos(_tasks())
      ..fail = true
      ..pending = Completer<void>();
    await _pumpHome(tester, todos);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(
      tester.widget<Checkbox>(find.byType(Checkbox).first).onChanged,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.more_vert).first,
          )
          .onPressed,
      isNull,
    );
    todos.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Today task 1'), findsOneWidget);
    expect(find.text(_l10n(tester).somethingWentWrong), findsOneWidget);
    expect(
      tester.widget<Checkbox>(find.byType(Checkbox).first).onChanged,
      isNotNull,
    );
  });

  for (final language in ['en', 'th']) {
    testWidgets('Home detail edits and menu confirms deletion ($language)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpHome(tester, _Todos(_tasks()), language: language);
      final l10n = _l10n(tester);
      await tester.tap(find.text('Today task 1'));
      await tester.pumpAndSettle();
      expect(find.byType(TodoDetailSheet), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(TodoDetailSheet),
          matching: find.byTooltip(l10n.moreActions),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, l10n.editTooltip));
      await tester.pumpAndSettle();
      expect(find.byType(TodoFormSheet), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Updated today');
      await tester.tap(find.widgetWithText(FilledButton, l10n.save));
      await tester.pumpAndSettle();
      expect(find.text('Updated today'), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.moreActions).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, l10n.deleteTooltip));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, l10n.cancel));
      await tester.pumpAndSettle();
      expect(find.text('Updated today'), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.moreActions).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, l10n.deleteTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
      await tester.pumpAndSettle();
      expect(find.text('Updated today'), findsNothing);
      expect(find.text('Today task 3'), findsOneWidget);
    });

    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('narrow layout ($language, dark=$dark, scale=$scale)', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(const Size(320, 700));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await _pumpHome(
            tester,
            _Todos(_tasks()),
            language: language,
            dark: dark,
            textScale: scale,
          );
          await tester.scrollUntilVisible(
            find.byType(LinearProgressIndicator),
            200,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('empty, loading, error and retry states', (tester) async {
    final todos = _Todos([]);
    await _pumpHome(tester, todos);
    expect(find.text(_l10n(tester).homeNoTasksToday), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    todos.state = const AsyncLoading();
    await tester.pump();
    expect(find.byType(AppLoading), findsOneWidget);
    todos.state = AsyncError(StateError('load failed'), StackTrace.current);
    await tester.pumpAndSettle();
    expect(find.byType(AppError), findsOneWidget);
    await tester.tap(find.text(_l10n(tester).retry));
    await tester.pumpAndSettle();
    expect(todos.retries, 1);
    expect(find.text(_l10n(tester).homeNoTasksToday), findsOneWidget);
  });

  testWidgets('View all switches to Tasks preserving its search', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoProvider.overrideWith(() => _Todos(_tasks()))],
        child: MaterialApp(
          theme: appTheme,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: AppShell(onLocaleChanged: (_) {}, onThemeModeChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LiquidGlassBottomNavigation>(
            find.byType(LiquidGlassBottomNavigation),
          )
          .selectedIndex,
      0,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('home-view-all')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-view-all')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Today task 3');
    await tester.pump(const Duration(milliseconds: 600));
    tester
        .widget<LiquidGlassBottomNavigation>(
          find.byType(LiquidGlassBottomNavigation),
        )
        .onSelected(0);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-view-all')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LiquidGlassBottomNavigation>(
            find.byType(LiquidGlassBottomNavigation),
          )
          .selectedIndex,
      1,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Today task 3',
    );
    expect(find.text('Today task 1'), findsNothing);
    expect(find.text('Today task 3'), findsWidgets);
  });
}
