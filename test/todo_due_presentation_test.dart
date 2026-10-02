import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/theme.dart';
import 'package:my_first_flutter_app/core/utils/date_time_utils.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_item.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_list.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';

Widget app(Widget child, {String language = 'en', bool dark = false}) =>
    MaterialApp(
      theme: dark ? appDarkTheme : appTheme,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  for (final language in ['en', 'th']) {
    for (final dark in [false, true]) {
      testWidgets('due labels and colors ($language, dark: $dark)', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final today = DateTime(2026, 10, 2, 23, 59);
        for (final scenario in [
          (-2, false),
          (-1, false),
          (0, false),
          (1, false),
          (2, false),
          (3, false),
          (4, false),
          (-1, true),
          (null, false),
        ]) {
          final offset = scenario.$1;
          final done = scenario.$2;
          final dueDate = offset == null
              ? null
              : DateTime(2026, 10, 2 + offset);
          await tester.pumpWidget(
            app(
              TodoItem(
                todo: Todo(
                  id: 'due',
                  title: 'Task',
                  details: '',
                  priority: 'high',
                  completed: done,
                  dueDate: dueDate,
                ),
                currentDate: today,
                itemNumber: 1,
                isBusy: false,
                onClick: () {},
                onToggle: () {},
                onEdit: () {},
                onDelete: () {},
              ),
              language: language,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(TodoItem));
          final l10n = AppLocalizations.of(context)!;
          final colors = Theme.of(context).colorScheme;
          final date = dueDate == null
              ? l10n.notSpecified
              : DateTimeUtils.formatDate(
                  dueDate,
                  localizations: MaterialLocalizations.of(context),
                );
          final suffix = offset == null || done || offset > 3
              ? null
              : offset < 0
              ? l10n.overdueDays(-offset)
              : offset == 0
              ? l10n.dueToday
              : l10n.daysRemaining(offset);
          final label = suffix == null ? date : '$date · $suffix';
          final text = tester.widget<Text>(find.text(label));
          final color = offset == null || done || offset > 3
              ? colors.onSurfaceVariant
              : offset <= 1
              ? colors.error
              : dark
              ? const Color(0xFFFFD166)
              : const Color(0xFF956000);
          expect(text.style!.color, color);
          expect(
            tester.widget<Icon>(find.byIcon(CupertinoIcons.clock)).color,
            color,
          );
          if (suffix != null) {
            expect(
              tester.getSize(find.text(label)).height,
              lessThanOrEqualTo(22),
            );
          }
          if (language == 'en') {
            expect(l10n.daysRemaining(1), '1 day remaining');
            expect(l10n.daysRemaining(3), '3 days remaining');
            expect(l10n.overdueDays(1), '1 day overdue');
            expect(l10n.overdueDays(2), '2 days overdue');
          }
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  Widget list(DateTime Function() clock) => app(
    TodoList(
      todos: [
        Todo(
          id: 'rollover',
          title: 'Task',
          details: '',
          completed: false,
          dueDate: DateTime(2026, 10, 2),
        ),
      ],
      showCompleted: null,
      busyIds: const {},
      now: clock,
      onTodoTap: (_) {},
      onToggle: (_) {},
      onEdit: (_) {},
      onDelete: (_) {},
    ),
  );

  testWidgets('list updates at midnight and cancels its timer on disposal', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 2, 23, 59);
    await tester.pumpWidget(list(() => now));
    await tester.pumpAndSettle();
    expect(find.textContaining('Due today'), findsOneWidget);
    now = DateTime(2026, 10, 3);
    await tester.pump(const Duration(minutes: 1));
    expect(find.textContaining('1 day overdue'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(days: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('list refreshes after backgrounding across multiple days', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 2, 12);
    await tester.pumpWidget(list(() => now));
    await tester.pumpAndSettle();
    expect(find.textContaining('Due today'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2026, 10, 5, 12);
    await tester.pump(const Duration(days: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.textContaining('3 days overdue'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
