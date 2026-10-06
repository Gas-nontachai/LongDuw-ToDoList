import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/features/todo/models/todo_due_status.dart';

void main() {
  final today = DateTime(2026, 10, 2, 23, 59);
  for (final entry in [
    (-1, TodoDueStatus.overdue),
    (0, TodoDueStatus.dueSoon),
    (1, TodoDueStatus.dueSoon),
    (3, TodoDueStatus.dueSoon),
    (4, TodoDueStatus.normal),
  ]) {
    test('calendar offset ${entry.$1} ignores time of day', () {
      final info = TodoDueInfo.calculate(
        dueDate: DateTime(2026, 10, 2 + entry.$1),
        completed: false,
        today: today,
      );
      expect(info.status, entry.$2);
      expect(info.daysRemaining, entry.$1);
    });
  }

  test('completed and unspecified dates have no countdown', () {
    final done = TodoDueInfo.calculate(
      dueDate: DateTime(2020),
      completed: true,
      today: today,
    );
    expect(done.status, TodoDueStatus.normal);
    expect(done.daysRemaining, isNull);
    final absent = TodoDueInfo.calculate(
      dueDate: null,
      completed: false,
      today: today,
    );
    expect(absent.status, TodoDueStatus.none);
    expect(absent.daysRemaining, isNull);
  });

  test('calendar differences cross month, year and leap day', () {
    for (final dates in [
      (DateTime(2026, 10, 31, 23), DateTime(2026, 11, 1)),
      (DateTime(2026, 12, 31, 23), DateTime(2027, 1, 1)),
      (DateTime(2024, 2, 28, 23), DateTime(2024, 2, 29)),
      (DateTime(2024, 2, 29, 23), DateTime(2024, 3, 1)),
    ]) {
      expect(
        TodoDueInfo.calculate(
          dueDate: dates.$2,
          completed: false,
          today: dates.$1,
        ).daysRemaining,
        1,
      );
    }
  });

  test('UTC date retains the date components displayed by the UI', () {
    expect(
      TodoDueInfo.calculate(
        dueDate: DateTime.utc(2026, 10, 2, 23, 59),
        completed: false,
        today: today,
      ).daysRemaining,
      0,
    );
  });
}
