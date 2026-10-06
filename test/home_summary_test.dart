import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/features/home/models/home_summary.dart';
import 'package:longdow_todo_list/features/todo/models/todo.dart';

Todo task(String id, {DateTime? due, bool completed = false}) =>
    Todo(id: id, title: id, details: '', completed: completed, dueDate: due);

void main() {
  final today = DateTime(2026, 10, 6, 12);

  test('preview keeps original order, caps at two, and counts all tasks', () {
    final summary = HomeSummary.calculate([
      task('overdue', due: DateTime(2026, 10, 5)),
      task('first', due: DateTime(2026, 10, 6, 23, 59)),
      task('finished', due: today, completed: true),
      task('no date'),
      task('tomorrow', due: DateTime(2026, 10, 7)),
      task('second', due: DateTime.utc(2026, 10, 6)),
      task('third', due: today),
      task('finished overdue', due: DateTime(2026, 10, 4), completed: true),
    ], today);
    expect(summary.todayPreview.map((todo) => todo.id), ['first', 'second']);
    expect(summary.dueToday, 3);
    expect(summary.overdue, 1);
    expect(summary.completed, 2);
    expect(summary.total, 8);
    expect(summary.remaining, 6);
    expect(summary.progress, .25);
  });

  test('empty and fully completed lists have safe progress values', () {
    final empty = HomeSummary.calculate([], today);
    expect(empty.progress, 0);
    expect(empty.remaining, 0);
    expect(empty.todayPreview, isEmpty);
    final done = HomeSummary.calculate([
      task('finished', due: today, completed: true),
    ], today);
    expect(done.progress, 1);
    expect(done.dueToday, 0);
    expect(done.todayPreview, isEmpty);
  });

  test(
    'calendar day rollover moves today into overdue and tomorrow into today',
    () {
      final tasks = [
        task('today', due: DateTime(2026, 10, 6, 23, 59)),
        task('tomorrow', due: DateTime(2026, 10, 7)),
      ];
      final before = HomeSummary.calculate(
        tasks,
        DateTime(2026, 10, 6, 23, 59),
      );
      final after = HomeSummary.calculate(tasks, DateTime(2026, 10, 7));
      expect(before.todayPreview.single.id, 'today');
      expect(before.overdue, 0);
      expect(after.todayPreview.single.id, 'tomorrow');
      expect(after.overdue, 1);
    },
  );
}
