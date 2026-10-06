import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/features/notifications/models/daily_summary.dart';
import 'package:longdow_todo_list/features/todo/models/todo.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

Todo task(String id, DateTime? due, {bool completed = false}) =>
    Todo(id: id, title: id, details: '', completed: completed, dueDate: due);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test(
    'counts only unfinished dated tasks by their displayed calendar day',
    () {
      final summary = DailySummary.calculate([
        task('today', DateTime(2026, 10, 5, 23, 59)),
        task('utc-today', DateTime.utc(2026, 10, 5, 23, 59)),
        task('overdue', DateTime(2026, 10, 4)),
        task('done', DateTime(2026, 10, 4), completed: true),
        task('done-today', DateTime(2026, 10, 5), completed: true),
        task('future', DateTime(2026, 10, 6)),
        task('undated', null),
      ], DateTime(2026, 10, 5, 8));
      expect(summary.today, 2);
      expect(summary.overdue, 1);
    },
  );

  test('future days get their own counts, including newly overdue work', () {
    final requests = planDailySummaries(
      todos: [
        task('a', DateTime(2026, 10, 5)),
        task('b', DateTime(2026, 10, 6)),
      ],
      now: DateTime.utc(2026, 10, 5),
      location: tz.getLocation('Asia/Bangkok'),
      reminderMinutes: 540,
    );
    expect(requests, hasLength(30));
    expect(requests.first.date.hour, 9);
    expect(requests.first.day, 20261005);
    expect(requests.first.summary.today, 1);
    expect(requests.first.summary.overdue, 0);
    expect(requests[1].summary.today, 1);
    expect(requests[1].summary.overdue, 1);
    expect(requests[2].summary.today, 0);
    expect(requests[2].summary.overdue, 2);
    expect(requests.map((r) => r.id).toSet(), hasLength(30));
  });

  test(
    'past time and consumed day both skip today without catch-up alerts',
    () {
      final location = tz.getLocation('Asia/Bangkok');
      for (final args in [(9, 0), (8, 20261005)]) {
        final requests = planDailySummaries(
          todos: [],
          now: tz.TZDateTime(location, 2026, 10, 5, args.$1),
          location: location,
          reminderMinutes: 540,
          consumedDay: args.$2,
        );
        expect(requests.first.day, 20261006);
        expect(requests, hasLength(30));
      }
    },
  );

  test('schedule stays at local 09:00 across both DST transitions', () {
    final location = tz.getLocation('America/New_York');
    for (final start in [
      tz.TZDateTime(location, 2026, 3, 7),
      tz.TZDateTime(location, 2026, 10, 31),
    ]) {
      final requests = planDailySummaries(
        todos: [],
        now: start,
        location: location,
        reminderMinutes: 540,
      );
      expect(
        requests.every((r) => r.date.hour == 9 && r.date.minute == 0),
        isTrue,
      );
      expect(
        requests[1].date.timeZoneOffset,
        isNot(requests.first.date.timeZoneOffset),
      );
    }
  });

  test('month, year and leap-day boundaries are calendar based', () {
    for (final dates in [
      (DateTime(2026, 12, 31), DateTime(2027, 1, 1)),
      (DateTime(2024, 2, 29), DateTime(2024, 3, 1)),
    ]) {
      final summary = DailySummary.calculate([task('a', dates.$1)], dates.$2);
      expect(summary.today, 0);
      expect(summary.overdue, 1);
    }
  });
}
