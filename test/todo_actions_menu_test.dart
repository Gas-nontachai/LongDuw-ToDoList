import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_actions_menu.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_item.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';

void main() {
  testWidgets('taps on rows or checkboxes only dismiss the open menu', (
    tester,
  ) async {
    final actions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              for (var i = 0; i < 2; i++)
                TodoItem(
                  todo: Todo(
                    id: '$i',
                    title: 'Task $i',
                    details: '',
                    completed: false,
                  ),
                  itemNumber: i + 1,
                  isBusy: false,
                  onClick: () => actions.add('view $i'),
                  onToggle: () => actions.add('toggle $i'),
                  onEdit: () => actions.add('edit $i'),
                  onDelete: () => actions.add('delete $i'),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final targets = [
      find.text('Task 0'),
      find.text('Task 1'),
      find.byType(Checkbox).first,
      find.byType(Checkbox).last,
    ];
    for (final target in targets) {
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNWidgets(3));
      await tester.tapAt(tester.getCenter(target));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      expect(actions, isEmpty);
    }

    // Once dismissed, the following tap can activate the row normally.
    await tester.tap(find.text('Task 1'));
    await tester.pumpAndSettle();
    expect(actions, ['view 1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu follows the selected anchor corner and offset', (
    tester,
  ) async {
    Future<Offset> menuPosition(Alignment alignment, Offset offset) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: TodoActionsMenu(
                animated: false,
                alignment: alignment,
                alignmentOffset: offset,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      final position = tester.getTopLeft(find.byType(MenuItemButton).first);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      return position;
    }

    final topLeft = await menuPosition(Alignment.topLeft, Offset.zero);
    final anchorSize = tester.getSize(find.byType(IconButton));
    final bottomRight = await menuPosition(
      Alignment.bottomRight,
      const Offset(12, 8),
    );
    expect(bottomRight.dx - topLeft.dx, closeTo(anchorSize.width + 12, 0.01));
    expect(bottomRight.dy - topLeft.dy, closeTo(anchorSize.height + 8, 0.01));
  });

  testWidgets('menu can reopen while its closing animation is running', (
    tester,
  ) async {
    final statuses = <AnimationStatus>[];
    VoidCallback? toggle;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: TodoActionsMenu(
              onEdit: () {},
              onDelete: () {},
              onAnimationStatusChanged: statuses.add,
              builder: (context, toggleMenu) {
                toggle = toggleMenu;
                return IconButton(
                  onPressed: toggleMenu,
                  icon: const Icon(Icons.more_vert),
                );
              },
            ),
          ),
        ),
      ),
    );

    toggle!();
    await tester.pumpAndSettle();
    expect(
      statuses,
      containsAllInOrder([AnimationStatus.forward, AnimationStatus.completed]),
    );

    toggle!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(statuses.last, AnimationStatus.reverse);
    expect(find.byType(MenuItemButton), findsNWidgets(2));

    toggle!();
    await tester.pumpAndSettle();
    expect(statuses.last, AnimationStatus.completed);
    expect(find.byType(MenuItemButton), findsNWidgets(2));

    // Outside taps must finish the exit animation and remove the overlay.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(statuses.last, AnimationStatus.dismissed);
    expect(find.byType(MenuItemButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final reducedMotion in [false, true]) {
    testWidgets('instant menu when reduced motion is $reducedMotion', (
      tester,
    ) async {
      final statuses = <AnimationStatus>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reducedMotion),
            child: Scaffold(
              body: Center(
                child: TodoActionsMenu(
                  animated: reducedMotion,
                  onEdit: () {},
                  onDelete: () {},
                  onAnimationStatusChanged: statuses.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      expect(statuses.last, AnimationStatus.completed);
      expect(statuses, isNot(contains(AnimationStatus.forward)));
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(statuses.last, AnimationStatus.dismissed);
      expect(find.byType(MenuItemButton), findsNothing);
    });
  }
}
