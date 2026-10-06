import '../../../core/config/priority_config.dart';
import '../../../core/utils/calendar_day.dart';
import '../../todo/models/todo.dart';

class StatsSummary {
  const StatsSummary({
    required this.total,
    required this.completed,
    required this.high,
    required this.medium,
    required this.low,
    required this.unspecified,
    required this.overdue,
    required this.dueToday,
    required this.dueSoon,
    required this.noDueDate,
    required this.later,
  });

  final int total;
  final int completed;
  final int high;
  final int medium;
  final int low;
  final int unspecified;
  final int overdue;
  final int dueToday;
  final int dueSoon;
  final int noDueDate;
  final int later;

  int get remaining => total - completed;
  double get progress => total == 0 ? 0 : completed / total;

  factory StatsSummary.calculate(List<Todo> todos, DateTime now) {
    final today = calendarDay(now);
    var completed = 0;
    var high = 0;
    var medium = 0;
    var low = 0;
    var unspecified = 0;
    var overdue = 0;
    var dueToday = 0;
    var dueSoon = 0;
    var noDueDate = 0;
    var later = 0;
    for (final todo in todos) {
      switch (todo.priority) {
        case PriorityConfig.high:
          high++;
        case PriorityConfig.medium:
          medium++;
        case PriorityConfig.low:
          low++;
        default:
          unspecified++;
      }
      if (todo.completed) {
        completed++;
        continue;
      }
      if (todo.dueDate == null) {
        noDueDate++;
        continue;
      }
      final days = calendarDay(todo.dueDate!).difference(today).inDays;
      if (days < 0) {
        overdue++;
      } else if (days == 0) {
        dueToday++;
      } else if (days <= 7) {
        dueSoon++;
      } else {
        later++;
      }
    }
    return StatsSummary(
      total: todos.length,
      completed: completed,
      high: high,
      medium: medium,
      low: low,
      unspecified: unspecified,
      overdue: overdue,
      dueToday: dueToday,
      dueSoon: dueSoon,
      noDueDate: noDueDate,
      later: later,
    );
  }
}
