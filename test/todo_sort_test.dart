import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/theme.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/providers/todo_provider.dart';
import 'package:my_first_flutter_app/features/todo/screens/todo_screen.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_item.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';

const _todos = [
  Todo(
    id: '1',
    title: 'Zulu',
    details: 'match',
    completed: false,
    priority: 'low',
  ),
  Todo(
    id: '2',
    title: 'alpha',
    details: 'match',
    completed: true,
    priority: 'medium',
  ),
  Todo(
    id: '3',
    title: 'Bravo',
    details: 'other',
    completed: true,
    priority: 'high',
  ),
];

class _TestTodos extends TodoNotifier {
  @override
  Future<List<Todo>> build() async => _todos;

  void replaceTodos(List<Todo> todos) => state = AsyncData(todos);
}

void main() {
  for (final language in ['en', 'th']) {
    testWidgets('sorting works with search and tabs on mobile ($language)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [todoProvider.overrideWith(_TestTodos.new)],
          child: MaterialApp(
            theme: appTheme,
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TodoScreen(
              onLocaleChanged: (_) {},
              onThemeModeChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TodoScreen)),
      )!;
      final sortButton = find.byWidgetPredicate(
        (widget) => widget is PopupMenuButton,
      );
      List<String> visibleTitles() => tester
          .widgetList<TodoItem>(find.byType(TodoItem))
          .map((item) => item.todo.title)
          .toList();
      Future<void> sortBy(String label) async {
        await tester.tap(sortButton);
        await tester.pumpAndSettle();
        await tester.tap(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (widget) => widget is CheckedPopupMenuItem,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text(l10n.taskCount(1)), findsOneWidget);
      expect(visibleTitles(), ['Zulu', 'alpha', 'Bravo']);
      expect(
        tester.getCenter(sortButton).dx,
        greaterThan(tester.getCenter(find.byType(TextField)).dx),
      );
      await sortBy(l10n.sortTitleAscending);
      expect(visibleTitles(), ['Zulu', 'alpha', 'Bravo']);
      await sortBy(l10n.sortTitleDescending);
      expect(visibleTitles(), ['Zulu', 'Bravo', 'alpha']);

      await tester.enterText(find.byType(TextField), 'match');
      await tester.pumpAndSettle();
      expect(visibleTitles(), ['Zulu', 'alpha']);
      expect(find.text(l10n.taskCount(1)), findsOneWidget);
      await sortBy(l10n.sortTitleAscending);
      expect(visibleTitles(), ['Zulu', 'alpha']);
      await tester.tap(find.byTooltip(l10n.clearSearchTooltip));
      await tester.pumpAndSettle();
      expect(visibleTitles(), ['Zulu', 'alpha', 'Bravo']);

      await tester.tap(find.text(l10n.completed).first);
      await tester.pumpAndSettle();
      expect(visibleTitles(), ['alpha', 'Bravo']);
      expect(find.text(l10n.taskCount(1)), findsOneWidget);
      await sortBy(l10n.sortTitleDescending);
      expect(visibleTitles(), ['Bravo', 'alpha']);
      await tester.tap(find.text(l10n.all));
      await tester.pumpAndSettle();
      await sortBy(l10n.sortOriginal);
      expect(visibleTitles(), ['Zulu', 'alpha', 'Bravo']);
      expect(_todos.map((todo) => todo.title), ['Zulu', 'alpha', 'Bravo']);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TodoScreen)),
      );
      (container.read(todoProvider.notifier) as _TestTodos).replaceTodos(
        _todos.sublist(1),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.taskCount(0)), findsOneWidget);
      await tester.tap(find.text(l10n.incomplete));
      await tester.pumpAndSettle();
      expect(find.text(l10n.taskCount(0)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
