import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/theme.dart';
import 'package:longdow_todo_list/features/todo/models/todo.dart';
import 'package:longdow_todo_list/features/todo/models/todo_query.dart';
import 'package:longdow_todo_list/features/todo/providers/todo_provider.dart';
import 'package:longdow_todo_list/app/app_shell.dart';
import 'package:longdow_todo_list/features/todo/widgets/todo_item.dart';
import 'package:longdow_todo_list/features/todo/widgets/todo_query_controls.dart';
import 'package:longdow_todo_list/l10n/app_localizations.dart';

const _items = [
  Todo(
    id: '1',
    title: 'Zulu',
    details: 'match',
    completed: false,
    priority: 'high',
  ),
  Todo(
    id: '2',
    title: 'Alpha',
    details: 'match',
    completed: false,
    priority: 'high',
  ),
  Todo(
    id: '3',
    title: 'Bravo',
    details: 'other',
    completed: false,
    priority: 'low',
  ),
  Todo(
    id: '4',
    title: 'Done',
    details: 'match',
    completed: true,
    priority: 'high',
  ),
];

class _TestTodos extends TodoNotifier {
  @override
  Future<List<Todo>> build() async => _items;
  void replace(List<Todo> items) => state = AsyncData(items);
  @override
  Future<void> refreshTodos() async {
    final items = state.value!;
    state = const AsyncLoading();
    await Future<void>.delayed(Duration.zero);
    state = AsyncData(items);
  }
}

void main() {
  for (final lang in ['en', 'th']) {
    for (final dark in [false, true]) {
      testWidgets(
        'filter drafts, sort, search, tabs and refresh ($lang, dark=$dark)',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            ProviderScope(
              overrides: [todoProvider.overrideWith(_TestTodos.new)],
              child: MaterialApp(
                theme: dark ? appDarkTheme : appTheme,
                locale: Locale(lang),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: AppShell(
                  onLocaleChanged: (_) {},
                  onThemeModeChanged: (_) {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('home-view-all')));
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.byType(AppShell)),
          )!;
          List<String> titles() => tester
              .widgetList<TodoItem>(find.byType(TodoItem))
              .map((item) => item.todo.title)
              .toList();
          Future<void> openFilter() async {
            await tester.tap(find.byKey(const ValueKey('todo-filter-button')));
            await tester.pumpAndSettle();
          }

          Future<void> tap(String label) async {
            await tester.ensureVisible(find.text(label).last);
            await tester.tap(find.text(label).last);
            await tester.pumpAndSettle();
          }

          await openFilter();
          await tap(l10n.priorityHigh);
          expect(find.text(l10n.applyFilters(1)), findsOneWidget);
          await tap(l10n.cancel);
          expect(titles(), ['Zulu', 'Alpha', 'Bravo', 'Done']);
          expect(find.byType(InputChip), findsNothing);
          await openFilter();
          await tap(l10n.priorityHigh);
          await tap(l10n.applyFilters(1));
          expect(titles(), ['Zulu', 'Alpha', 'Done']);
          expect(find.byType(InputChip), findsNothing);
          expect(
            tester
                .widget<TodoQueryButton>(
                  find.byKey(const ValueKey('todo-filter-button')),
                )
                .isActive,
            isTrue,
          );
          await openFilter();
          await tap(l10n.resetQuery);
          expect(find.text(l10n.applyFilters(0)), findsOneWidget);
          await tap(l10n.cancel);
          expect(titles(), ['Zulu', 'Alpha', 'Done']);
          // Dismissing a draft via the modal barrier does not apply it.
          await openFilter();
          await tap(l10n.priorityLow);
          await tester.tapAt(const Offset(8, 32));
          await tester.pumpAndSettle();
          expect(titles(), ['Zulu', 'Alpha', 'Done']);

          await tester.tap(find.byKey(const ValueKey('todo-sort-button')));
          await tester.pumpAndSettle();
          await tap(l10n.sortTitleAscending);
          await tap(l10n.cancel);
          expect(titles(), ['Zulu', 'Alpha', 'Done']);
          await tester.tap(find.byKey(const ValueKey('todo-sort-button')));
          await tester.pumpAndSettle();
          await tap(l10n.sortTitleAscending);
          await tap(l10n.applySort);
          expect(titles(), ['Alpha', 'Zulu', 'Done']);
          await tester.enterText(find.byType(TextField), 'match');
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.completed).first);
          await tester.pumpAndSettle();
          expect(titles(), ['Done']);
          await tester.tap(find.text(l10n.all));
          await tester.pumpAndSettle();
          final notifier = ProviderScope.containerOf(
            tester.element(find.byType(AppShell)),
          ).read(todoProvider.notifier) as _TestTodos;
          final refresh = notifier.refreshTodos();
          await tester.pumpAndSettle();
          await refresh;
          expect(titles(), ['Alpha', 'Zulu', 'Done']);
          // Newly added/edited data immediately participates in the current query.
          notifier.replace([
            ..._items.map(
              (item) => item.id == '1' ? item.copyWith(priority: 'low') : item,
            ),
            const Todo(
              id: '5',
              title: 'Added',
              details: 'match',
              completed: false,
              priority: 'high',
            ),
          ]);
          await tester.pumpAndSettle();
          expect(titles(), ['Added', 'Alpha', 'Done']);
          await openFilter();
          await tap(l10n.resetQuery);
          await tap(l10n.applyFilters(0));
          expect(titles(), ['Added', 'Alpha', 'Zulu', 'Done']);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'match',
          );
          expect(
            tester
                .widget<TodoQueryButton>(
                  find.byKey(const ValueKey('todo-sort-button')),
                )
                .isActive,
            isTrue,
          );
          await tester.tap(find.byKey(const ValueKey('todo-sort-button')));
          await tester.pumpAndSettle();
          await tap(l10n.resetQuery);
          await tap(l10n.cancel);
          expect(titles(), ['Added', 'Alpha', 'Zulu', 'Done']);
          await tester.tap(find.byKey(const ValueKey('todo-sort-button')));
          await tester.pumpAndSettle();
          await tap(l10n.resetQuery);
          await tap(l10n.applySort);
          expect(titles(), ['Zulu', 'Alpha', 'Added', 'Done']);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('range selection and every selected filter fit a small screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    TodoFilter? result;
    final initial = TodoFilter(
      priorities: {'high', 'medium', 'low'},
      dueFilters: TodoDueFilter.values.toSet(),
      duePresence: TodoDuePresence.hasDate,
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        locale: const Locale('th'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showTodoFilterSheet(context, initial),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SegmentedButton<TodoDateField>)),
    )!;
    await tester.ensureVisible(find.text(l10n.createdAt));
    await tester.tap(find.text(l10n.createdAt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.applyFilters(9)));
    await tester.pumpAndSettle();
    expect(result!.dateField, TodoDateField.createdAt);
    expect(result!.startDate, DateTime(2026, 10, 1));
    expect(result!.endDate, DateTime(2026, 10, 31));
    expect(tester.takeException(), isNull);
  });
  testWidgets('date range picker validates, saves and cancels draft dates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    TodoFilter? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showTodoFilterSheet(
                context,
                result ?? TodoFilter(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SegmentedButton<TodoDateField>));
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    await tester.ensureVisible(find.text(l10n.selectDateRange));
    await tester.tap(find.text(l10n.selectDateRange));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(material.inputDateModeButtonLabel));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      material.formatCompactDate(DateTime(2026, 10, 5)),
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      material.formatCompactDate(DateTime(2026, 10, 2)),
    );
    await tester.tap(find.text(material.okButtonLabel));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).at(1),
      material.formatCompactDate(DateTime(2026, 10, 9)),
    );
    await tester.tap(find.text(material.okButtonLabel));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(find.text(l10n.applyFilters(1)), findsOneWidget);
    await tester.tap(find.byIcon(Icons.date_range_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.applyFilters(1)), findsOneWidget);
    await tester.tap(find.text(l10n.applyFilters(1)));
    await tester.pumpAndSettle();
    expect(result!.startDate, DateTime(2026, 10, 5));
    expect(result!.endDate, DateTime(2026, 10, 9));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.clearDateRange));
    await tester.tap(find.text(l10n.clearDateRange));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.applyFilters(0)));
    await tester.pumpAndSettle();
    expect(result!.startDate, isNull);
    expect(result!.endDate, isNull);
    expect(tester.takeException(), isNull);
  });
  for (final lang in ['en', 'th']) {
    testWidgets('no due date clears and disables due controls ($lang)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      TodoFilter? result;
      final initial = TodoFilter(
        dueFilters: {TodoDueFilter.today, TodoDueFilter.overdue},
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await showTodoFilterSheet(context, initial),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RadioGroup<TodoDuePresence>)),
      )!;
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      OutlinedButton rangeButton() => tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.byIcon(Icons.date_range_outlined),
          matching: find.byType(OutlinedButton),
        ),
      );
      await tap(l10n.noDueDate);
      expect(
        tester
            .widget<RadioGroup<TodoDuePresence>>(
              find.byType(RadioGroup<TodoDuePresence>),
            )
            .groupValue,
        TodoDuePresence.noDate,
      );
      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(checkbox.value, isFalse);
        expect(checkbox.onChanged, isNull);
      }
      expect(find.text(l10n.applyFilters(1)), findsOneWidget);
      expect(find.text(l10n.clearDateRange), findsNothing);
      expect(rangeButton().onPressed, isNull);
      final segment = tester.widget<SegmentedButton<TodoDateField>>(
        find.byType(SegmentedButton<TodoDateField>),
      );
      expect(segment.segments.first.enabled, isFalse);
      await tap(l10n.createdAt);
      expect(rangeButton().onPressed, isNotNull);
      await tap(l10n.hasDueDate);
      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(checkbox.value, isFalse);
        expect(checkbox.onChanged, isNotNull);
      }
      expect(
        tester
            .widget<SegmentedButton<TodoDateField>>(
              find.byType(SegmentedButton<TodoDateField>),
            )
            .segments
            .first
            .enabled,
        isTrue,
      );
      await tap(l10n.all);
      expect(find.text(l10n.applyFilters(0)), findsOneWidget);
      await tap(l10n.filterToday);
      expect(find.text(l10n.applyFilters(1)), findsOneWidget);
      await tap(l10n.noDueDate);
      await tap(l10n.applyFilters(1));
      expect(result!.duePresence, TodoDuePresence.noDate);
      expect(result!.dueFilters, isEmpty);
      expect(result!.startDate, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
