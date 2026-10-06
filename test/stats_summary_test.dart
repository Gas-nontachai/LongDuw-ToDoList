import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/features/stats/models/stats_summary.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';

Todo task({
  bool completed = false,
  String priority = 'medium',
  DateTime? due,
}) => Todo(
  id: 'task',
  title: '',
  details: '',
  completed: completed,
  priority: priority,
  dueDate: due,
);

void main() {
  final now = DateTime(2026, 12, 31, 12);

  test('counts all priorities but only remaining tasks by due date', () {
    final summary = StatsSummary.calculate([
      task(priority: 'high', due: DateTime(2026, 12, 30)),
      task(priority: 'high', due: DateTime.utc(2026, 12, 31, 23, 59)),
      task(priority: 'low', due: DateTime(2027, 1, 1)),
      task(priority: 'low', due: DateTime(2027, 1, 7)),
      task(due: DateTime(2027, 1, 8)),
      task(priority: ''),
      task(priority: 'unexpected', completed: true),
      task(priority: 'high', completed: true, due: DateTime(2026, 12, 30)),
      task(completed: true, due: now),
      task(completed: true, due: DateTime(2027, 1, 1)),
      task(completed: true, due: DateTime(2027, 1, 8)),
    ], now);
    expect(summary.total, 11);
    expect(summary.completed, 5);
    expect(summary.remaining, 6);
    expect(
      [summary.high, summary.medium, summary.low, summary.unspecified],
      [3, 4, 2, 2],
    );
    expect(
      [
        summary.overdue,
        summary.dueToday,
        summary.dueSoon,
        summary.noDueDate,
        summary.later,
      ],
      [1, 1, 2, 1, 1],
    );
  });

  test('empty and fully completed lists have safe values', () {
    final empty = StatsSummary.calculate([], now);
    expect(empty.progress, 0);
    expect(empty.remaining, 0);
    final done = StatsSummary.calculate([
      task(completed: true, due: now),
      task(completed: true),
    ], now);
    expect(done.progress, 1);
    expect(done.remaining, 0);
    expect(done.dueToday + done.noDueDate, 0);
  });

  test('reference counts produce 58 percent', () {
    final summary = StatsSummary.calculate([
      for (var i = 0; i < 12; i++) task(completed: i < 7),
    ], now);
    expect(summary.total, 12);
    expect(summary.completed, 7);
    expect(summary.remaining, 5);
    expect((summary.progress * 100).round(), 58);
  });

  test('calendar rollover reclassifies dates across month and year', () {
    final todos = [task(due: now), task(due: DateTime(2027, 1, 1))];
    final before = StatsSummary.calculate(todos, now);
    final after = StatsSummary.calculate(todos, DateTime(2027, 1, 1));
    expect([before.overdue, before.dueToday, before.dueSoon], [0, 1, 1]);
    expect([after.overdue, after.dueToday, after.dueSoon], [1, 1, 0]);
  });
}
