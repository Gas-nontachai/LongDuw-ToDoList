import 'package:timezone/timezone.dart' as tz;

import '../../../core/utils/calendar_day.dart';
import '../../todo/models/todo.dart';

class DailySummary {
  const DailySummary({required this.today, required this.overdue});

  final int today;
  final int overdue;

  factory DailySummary.calculate(List<Todo> todos, DateTime date) {
    final day = calendarDay(date);
    var today = 0;
    var overdue = 0;
    for (final todo in todos) {
      if (todo.completed || todo.dueDate == null) continue;
      final due = calendarDay(todo.dueDate!);
      if (due == day) today++;
      if (due.isBefore(day)) overdue++;
    }
    return DailySummary(today: today, overdue: overdue);
  }
}

class DailySummaryRequest {
  const DailySummaryRequest({required this.date, required this.summary});

  final tz.TZDateTime date;
  final DailySummary summary;
  int get day => calendarDayKey(date);
  int get id => idBase + day;

  // Reserve a namespace so cancellation never touches other notifications.
  static const idBase = 100000000;
  static bool ownsId(int id) => id >= idBase && id < idBase + 100000000;
}

List<DailySummaryRequest> planDailySummaries({
  required List<Todo> todos,
  required DateTime now,
  required tz.Location location,
  required int reminderMinutes,
  int consumedDay = 0,
  int horizon = 30,
}) {
  final localNow = tz.TZDateTime.from(now, location);
  final first = tz.TZDateTime(
    location,
    localNow.year,
    localNow.month,
    localNow.day,
    reminderMinutes ~/ 60,
    reminderMinutes % 60,
  );
  final startOffset =
      first.isAfter(localNow) && calendarDayKey(first) > consumedDay ? 0 : 1;
  return [
    for (var offset = startOffset; offset < startOffset + horizon; offset++)
      // Construct each calendar day separately: adding 24h drifts across DST.
      for (final date in [
        tz.TZDateTime(
          location,
          localNow.year,
          localNow.month,
          localNow.day + offset,
          reminderMinutes ~/ 60,
          reminderMinutes % 60,
        ),
      ])
        if (date.isAfter(localNow) && calendarDayKey(date) > consumedDay)
          DailySummaryRequest(
            date: date,
            summary: DailySummary.calculate(todos, date),
          ),
  ];
}
