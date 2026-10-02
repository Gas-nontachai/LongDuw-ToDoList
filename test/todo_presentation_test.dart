import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_detail.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_item.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_priority_badge.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';

Widget app(Widget child, String language) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'row opens details, overflow routes actions, checkbox only toggles',
    (tester) async {
      final actions = <String>[];
      await tester.pumpWidget(
        app(
          TodoItem(
            todo: Todo(
              id: 'menu',
              title: 'Task menu',
              completed: false,
              details: '',
              dueDate: DateTime(2026, 10, 2),
            ),
            itemNumber: 1,
            isBusy: false,
            onClick: () => actions.add('view'),
            onToggle: () => actions.add('toggle'),
            onEdit: () => actions.add('edit'),
            onDelete: () => actions.add('delete'),
          ),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(actions, ['toggle']);
      expect(find.byType(MenuItemButton), findsNothing);
      await tester.tap(find.text('Task menu'));
      await tester.pumpAndSettle();
      expect(actions, ['toggle', 'view']);
      expect(find.byType(MenuItemButton), findsNothing);
      for (final action in [
        ('View', 'view'),
        ('Edit', 'edit'),
        ('Delete', 'delete'),
      ]) {
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        expect(find.byType(MenuItemButton), findsNWidgets(3));
        await tester.tap(find.text(action.$1));
        await tester.pumpAndSettle();
        expect(actions.last, action.$2);
        expect(find.byType(MenuItemButton), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('short detail fits content and can expand and collapse', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(
        TodoDetailSheet(
          todo: Todo(
            id: 'short',
            title: 'Todo 4',
            details: 'Details for todo 4',
            completed: false,
            dueDate: DateTime(2026, 10, 3),
          ),
        ),
        'en',
      ),
    );
    await tester.pumpAndSettle();
    final sheet = find.byKey(const ValueKey('expandable-sheet'));
    final compactHeight = tester.getSize(sheet).height;
    expect(compactHeight, lessThan(600));
    final lastValue = find.byType(SelectableText).last;
    final close = find.byType(FilledButton);
    expect(
      tester.getRect(close).top - tester.getRect(lastValue).bottom,
      lessThan(60),
    );
    await tester.tap(find.byTooltip('Expand to full screen'));
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(900, 1));
    await tester.tap(find.byTooltip('Collapse sheet'));
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(compactHeight, 1));
    expect(find.text('Details for todo 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 800.0]) {
    testWidgets('detail fills sheet width and contains long text ($width)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final title = List.filled(100, 'LongTitleชื่อยาว').join();
      await tester.pumpWidget(
        app(
          TodoDetailSheet(
            todo: Todo(
              id: '1',
              title: title,
              completed: false,
              priority: 'medium',
              details: title,
            ),
          ),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      final dialog = find.byKey(const ValueKey('expandable-sheet'));
      final bounds = tester.getRect(dialog);
      expect(bounds.width, closeTo(width, 1));
      final dueLabel = tester.getTopLeft(find.text('Due date'));
      final createdLabel = tester.getTopLeft(find.text('Created at'));
      expect(createdLabel.dy, closeTo(dueLabel.dy, 1));
      expect(createdLabel.dx, greaterThan(dueLabel.dx));
      if (width >= 520) {
        final menuBounds = tester.getRect(find.byTooltip('More actions'));
        final badgeBounds = tester.getRect(find.byType(TodoPriorityBadge));
        expect(menuBounds.right, closeTo(bounds.right - 24, 1));
        expect(menuBounds.left - badgeBounds.right, closeTo(8, 1));
        expect(menuBounds.center.dy, closeTo(badgeBounds.center.dy, 1));
        expect(createdLabel.dy, closeTo(dueLabel.dy, 1));
        expect(createdLabel.dx, greaterThan(dueLabel.dx));
        expect(
          tester.getCenter(find.text('Medium')).dy,
          closeTo(tester.getCenter(find.text('Incomplete')).dy, 2),
        );
      }

      for (final element in find.byType(SelectableText).evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(rect.left, greaterThanOrEqualTo(bounds.left));
        expect(rect.right, lessThanOrEqualTo(bounds.right));
      }
      expect(find.text(title), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in ['en', 'th']) {
    for (final completed in [false, true]) {
      testWidgets(
        'detail badges adapt when resized ($language, completed: $completed)',
        (tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          for (final width in [400.0, 1200.0, 320.0]) {
            await tester.binding.setSurfaceSize(Size(width, 700));
            await tester.pumpWidget(
              app(
                TodoDetailSheet(
                  todo: Todo(
                    id: 'responsive',
                    title: 'Task',
                    completed: completed,
                    priority: 'medium',
                    details: 'Details body',
                    dueDate: DateTime(2026, 10, 5),
                    createdAt: DateTime(2026, 10, 1, 10, 30),
                  ),
                ),
                language,
              ),
            );
            await tester.pumpAndSettle();
            final context = tester.element(find.byType(TodoDetailSheet));
            final l10n = AppLocalizations.of(context)!;
            final dueLabel = tester.getTopLeft(find.text(l10n.dueDate));
            final createdLabel = tester.getTopLeft(find.text(l10n.createdAt));
            expect(createdLabel.dy, closeTo(dueLabel.dy, 1));
            expect(createdLabel.dx, greaterThan(dueLabel.dx));
            final values = find.byType(SelectableText);
            final dueBounds = tester.getRect(values.at(2));
            final createdBounds = tester.getRect(values.at(3));
            expect(dueBounds.right, lessThan(createdBounds.left));
            final status = completed ? l10n.completed : l10n.incomplete;
            final compact = width < 1200;
            expect(
              tester
                  .widget<TodoPriorityBadge>(find.byType(TodoPriorityBadge))
                  .compact,
              compact,
            );
            expect(find.text(status), compact ? findsNothing : findsOneWidget);
            expect(
              find.text(l10n.priorityMedium),
              compact ? findsNothing : findsOneWidget,
            );
            expect(find.byTooltip('${l10n.status}: $status'), findsOneWidget);
            if (compact) {
              expect(
                find.byTooltip('${l10n.priority}: ${l10n.priorityMedium}'),
                findsOneWidget,
              );
              expect(
                find.byIcon(
                  completed
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                ),
                findsOneWidget,
              );
            }
            // Badges must not squeeze the heading below its natural width
            // unless the sheet itself is too narrow for that text.
            final heading = find.text(l10n.details).first;
            final paragraph = tester.renderObject<RenderParagraph>(heading);
            expect(
              tester.getSize(heading).width,
              greaterThanOrEqualTo(
                math.min(
                      paragraph.getMaxIntrinsicWidth(double.infinity),
                      width - 48 - 38,
                    ) -
                    0.1,
              ),
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets(
    'detail supports large Thai text in dark mode on a small screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          locale: const Locale('th'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: TodoDetailSheet(
              todo: Todo(
                id: '1',
                title: 'ชื่อรายการที่ยาวมาก',
                dueDate: DateTime(2026, 10, 5),
                createdAt: DateTime(2026, 10, 1, 10, 30),
                completed: false,
                details: 'รายละเอียดทั้งหมด',
                priority: 'medium',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ชื่อรายการที่ยาวมาก'), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TodoDetailSheet)),
      )!;
      final dueLabel = tester.getTopLeft(find.text(l10n.dueDate));
      final createdLabel = tester.getTopLeft(find.text(l10n.createdAt));
      expect(createdLabel.dy, closeTo(dueLabel.dy, 1));
      expect(createdLabel.dx, greaterThan(dueLabel.dx));
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['en', 'th']) {
    testWidgets(
      'long title keeps its flag aligned with the menu at 320px ($language)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final title = List.filled(
          20,
          'Long task title ชื่อรายการยาว',
        ).join(' ');
        await tester.pumpWidget(
          app(
            TodoItem(
              todo: Todo(
                id: '1',
                title: title,
                completed: false,
                details: '',
                priority: 'high',
              ),
              itemNumber: 1,
              isBusy: false,
              onClick: () {},
              onToggle: () {},
              onEdit: () {},
              onDelete: () {},
            ),
            language,
          ),
        );
        await tester.pumpAndSettle();
        final titleWidget = tester.widget<Text>(find.text(title));
        expect(titleWidget.maxLines, 1);
        expect(titleWidget.overflow, TextOverflow.ellipsis);
        final flag = find.byType(TodoPriorityBadge);
        expect(tester.widget<TodoPriorityBadge>(flag).compact, isTrue);
        expect(
          tester.getCenter(flag).dy,
          closeTo(tester.getCenter(find.byIcon(Icons.more_vert)).dy, 1),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'details show every field and scroll long content ($language)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 480));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final details = List.filled(60, 'Full details รายละเอียด').join('\n');
        await tester.pumpWidget(
          app(
            TodoDetailSheet(
              todo: Todo(
                id: 'task-123',
                title: 'Full task title',
                completed: true,
                details: details,
                priority: 'high',
                createdAt: DateTime(2026, 10, 1, 10, 30),
                dueDate: DateTime(2026, 10, 5),
              ),
            ),
            language,
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(TodoDetailSheet));
        final l10n = AppLocalizations.of(context)!;
        expect(find.text('Full task title'), findsOneWidget);
        expect(find.text(details), findsOneWidget);
        expect(find.text(l10n.completed), findsNothing);
        expect(
          find.byTooltip('${l10n.status}: ${l10n.completed}'),
          findsOneWidget,
        );
        expect(find.text(l10n.createdAt), findsOneWidget);
        expect(find.text(l10n.dueDate), findsOneWidget);
        expect(
          find.text(
            MaterialLocalizations.of(context)
                .formatMediumDate(DateTime(2026, 10, 5)),
          ),
          findsOneWidget,
        );
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
