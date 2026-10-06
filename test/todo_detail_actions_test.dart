import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/features/todo/models/todo.dart';
import 'package:longdow_todo_list/features/todo/providers/todo_provider.dart';
import 'package:longdow_todo_list/app/app_shell.dart';
import 'package:longdow_todo_list/features/todo/widgets/todo_detail.dart';
import 'package:longdow_todo_list/features/todo/widgets/todo_form.dart';
import 'package:longdow_todo_list/l10n/app_localizations.dart';

class _Todos extends TodoNotifier {
  Todo? updated;
  Todo? deleted;

  @override
  Future<List<Todo>> build() async => const [
    Todo(
      id: '1',
      title: 'Original task',
      details: 'Task details',
      completed: false,
    ),
  ];

  @override
  Future<void> updateTodo(Todo todo) async {
    updated = todo;
    state = AsyncData([todo]);
  }

  @override
  Future<void> deleteTodo(Todo todo) async {
    deleted = todo;
    state = const AsyncData([]);
  }
}

void main() {
  for (final language in ['en', 'th']) {
    testWidgets(
      'detail edits the selected task and confirms deletion ($language)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final todos = _Todos();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [todoProvider.overrideWith(() => todos)],
            child: MaterialApp(
              locale: Locale(language),
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
        await tester.tap(find.text('Original task'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(TodoDetailSheet),
            matching: find.byTooltip(l10n.moreActions),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(MenuItemButton, l10n.editTooltip));
        await tester.pumpAndSettle();
        expect(find.byType(TodoDetailSheet), findsNothing);
        expect(find.byType(TodoFormSheet), findsOneWidget);
        expect(find.text('Task details'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).first,
          'Updated task',
        );
        await tester.tap(find.widgetWithText(FilledButton, l10n.save));
        await tester.pumpAndSettle();
        expect(todos.updated?.id, '1');
        expect(todos.updated?.title, 'Updated task');
        expect(find.text('Updated task'), findsOneWidget);

        await tester.tap(find.text('Updated task'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(TodoDetailSheet),
            matching: find.byTooltip(l10n.moreActions),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(MenuItemButton, l10n.deleteTooltip),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(l10n.removeTodoConfirmation('Updated task')),
          findsOneWidget,
        );
        expect(todos.deleted, isNull);
        await tester.tap(find.widgetWithText(TextButton, l10n.cancel));
        await tester.pumpAndSettle();
        expect(todos.deleted, isNull);
        expect(find.text('Updated task'), findsOneWidget);

        await tester.tap(find.text('Updated task'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(TodoDetailSheet),
            matching: find.byTooltip(l10n.moreActions),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(MenuItemButton, l10n.deleteTooltip),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
        await tester.pumpAndSettle();
        expect(todos.deleted?.id, '1');
        expect(find.text('Updated task'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
