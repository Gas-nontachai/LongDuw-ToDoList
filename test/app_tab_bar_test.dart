import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/theme.dart';
import 'package:longdow_todo_list/features/todo/models/todo.dart';
import 'package:longdow_todo_list/features/todo/widgets/tab_todo.dart';
import 'package:longdow_todo_list/l10n/app_localizations.dart';
import 'package:longdow_todo_list/shared/widgets/app_tab_bar.dart';

void main() {
  testWidgets('selection is controlled by the caller and tabs expand evenly', (
    tester,
  ) async {
    int? requestedIndex;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: AppTabBar(
            tabs: const ['All', 'To Do', 'In Progress', 'Done'],
            selectedIndex: 1,
            onChanged: (index) => requestedIndex = index,
          ),
        ),
      ),
    );

    final targets = find.descendant(
      of: find.byType(AppTabBar),
      matching: find.byType(InkWell),
    );
    final firstSize = tester.getSize(targets.at(0));
    expect(firstSize.height, greaterThanOrEqualTo(32));
    for (var index = 1; index < 4; index++) {
      expect(tester.getSize(targets.at(index)).width, firstSize.width);
      expect(tester.getSize(targets.at(index)).height, firstSize.height);
    }

    for (var index = 0; index < 4; index++) {
      final label = ['All', 'To Do', 'In Progress', 'Done'][index];
      final targetCenter = tester.getCenter(targets.at(index));
      final labelCenter = tester.getCenter(find.text(label));
      expect(labelCenter.dx, closeTo(targetCenter.dx, 0.1));
      expect(labelCenter.dy, closeTo(targetCenter.dy, 0.1));
    }

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(requestedIndex, 3);
    expect(tester.widget<AppTabBar>(find.byType(AppTabBar)).selectedIndex, 1);
    expect(
      tester.getSemantics(targets.at(1)),
      matchesSemantics(
        label: 'To Do',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  for (final locale in const [Locale('en'), Locale('th')]) {
    testWidgets(
      'Todo taps and swipes stay synchronized in ${locale.languageCode}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme,
            darkTheme: appDarkTheme,
            themeMode: ThemeMode.dark,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TabBarTodo(
                todos: const [
                  Todo(
                    id: '1',
                    title: 'Finished task',
                    details: '',
                    completed: true,
                  ),
                  Todo(
                    id: '2',
                    title: 'Pending task',
                    details: '',
                    completed: false,
                  ),
                ],
                busyIds: const {},
                onTodoTap: (_) {},
                onToggle: (_) {},
                onEdit: (_) {},
                onDelete: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        AppTabBar selector() =>
            tester.widget<AppTabBar>(find.byType(AppTabBar));
        expect(selector().selectedIndex, 0);
        expect(
          selector().tabs.first,
          locale.languageCode == 'th' ? 'ทั้งหมด' : 'All',
        );
        expect(find.text('Finished task').hitTestable(), findsOneWidget);
        expect(find.text('Pending task').hitTestable(), findsOneWidget);

        await tester.tap(find.text(selector().tabs[1]));
        await tester.pumpAndSettle();
        expect(selector().selectedIndex, 1);
        expect(find.text('Pending task').hitTestable(), findsOneWidget);
        expect(find.text('Finished task').hitTestable(), findsNothing);

        await tester.drag(find.byType(TabBarView), const Offset(-600, 0));
        await tester.pumpAndSettle();
        expect(selector().selectedIndex, 2);
        expect(find.text('Finished task').hitTestable(), findsOneWidget);
        expect(find.text('Pending task').hitTestable(), findsNothing);

        await tester.tap(find.text(selector().tabs[0]));
        await tester.pumpAndSettle();
        expect(selector().selectedIndex, 0);
        expect(find.text('Finished task').hitTestable(), findsOneWidget);
        expect(find.text('Pending task').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
