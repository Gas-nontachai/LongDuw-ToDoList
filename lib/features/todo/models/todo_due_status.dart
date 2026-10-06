import '../../../core/utils/calendar_day.dart';

enum TodoDueStatus { none, normal, dueSoon, overdue }

class TodoDueInfo {
  const TodoDueInfo(this.status, {this.daysRemaining});

  final TodoDueStatus status;
  final int? daysRemaining;

  static TodoDueInfo calculate({
    required DateTime? dueDate,
    required bool completed,
    required DateTime today,
  }) {
    if (dueDate == null) return const TodoDueInfo(TodoDueStatus.none);
    if (completed) return const TodoDueInfo(TodoDueStatus.normal);

    // UTC here compares calendar components, without time or DST offsets.
    // Keep the same date components that the UI displays for dueDate.
    final dueDay = calendarDay(dueDate);
    final currentDay = calendarDay(today);
    final days = dueDay.difference(currentDay).inDays;
    return TodoDueInfo(
      days < 0
          ? TodoDueStatus.overdue
          : days <= 3
          ? TodoDueStatus.dueSoon
          : TodoDueStatus.normal,
      daysRemaining: days,
    );
  }
}
