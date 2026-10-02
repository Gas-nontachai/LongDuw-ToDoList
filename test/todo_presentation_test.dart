import 'package:flutter/material.dart';
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
  for (final width in [320.0, 800.0]) {
    testWidgets(
      'detail uses 70% of available width and contains long text ($width)',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final title = List.filled(100, 'LongTitleชื่อยาว').join();
        await tester.pumpWidget(
          app(
            TodoDetailDialog(
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
        final dialog = find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first;
        final bounds = tester.getRect(dialog);
        expect(bounds.width, closeTo(width * 0.7, 1));
        final dueLabel = tester.getTopLeft(find.text('Due date'));
        final createdLabel = tester.getTopLeft(find.text('Created at'));
        if (width * 0.7 >= 520) {
          expect(
            tester.getRect(find.byType(TodoPriorityBadge)).right,
            closeTo(bounds.right - 24, 1),
          );
          expect(createdLabel.dy, closeTo(dueLabel.dy, 1));
          expect(createdLabel.dx, greaterThan(dueLabel.dx));
          expect(
            tester.getCenter(find.text('Medium')).dy,
            closeTo(tester.getCenter(find.text('Incomplete')).dy, 2),
          );
        } else {
          expect(createdLabel.dy, greaterThan(dueLabel.dy));
        }

        for (final element in find.byType(SelectableText).evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.left, greaterThanOrEqualTo(bounds.left));
          expect(rect.right, lessThanOrEqualTo(bounds.right));
        }
        expect(find.text(title), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
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
          home: const Scaffold(
            body: TodoDetailDialog(
              todo: Todo(
                id: '1',
                title: 'ชื่อรายการที่ยาวมาก',
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
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['en', 'th']) {
    testWidgets('long title keeps its flag inline at 320px ($language)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final title = List.filled(20, 'Long task title ชื่อรายการยาว').join(' ');
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
        closeTo(tester.getCenter(find.text(title)).dy, 1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'details show every field and scroll long content ($language)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 480));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final details = List.filled(60, 'Full details รายละเอียด').join('\n');
        await tester.pumpWidget(
          app(
            TodoDetailDialog(
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
        final context = tester.element(find.byType(TodoDetailDialog));
        final l10n = AppLocalizations.of(context)!;
        expect(find.text('Full task title'), findsOneWidget);
        expect(find.text(details), findsOneWidget);
        expect(find.text(l10n.completed), findsOneWidget);
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
