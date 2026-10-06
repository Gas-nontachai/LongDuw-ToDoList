import '../../../core/utils/calendar_day.dart';
import '../../todo/models/todo.dart';

class HomeSummary {
  const HomeSummary({
    required this.total,
    required this.completed,
    required this.dueToday,
    required this.overdue,
    required this.todayPreview,
  });

  final int total;
  final int completed;
  final int dueToday;
  final int overdue;
  final List<Todo> todayPreview;

  int get remaining => total - completed;
  double get progress => total == 0 ? 0 : completed / total;

  factory HomeSummary.calculate(List<Todo> todos, DateTime now) {
    final today = calendarDay(now);
    var completed = 0;
    var dueToday = 0;
    var overdue = 0;
    final preview = <Todo>[];
    for (final todo in todos) {
      if (todo.completed) {
        completed++;
        continue;
      }
      if (todo.dueDate == null) continue;
      final due = calendarDay(todo.dueDate!);
      if (due == today) {
        dueToday++;
        if (preview.length < 2) preview.add(todo);
      } else if (due.isBefore(today)) {
        overdue++;
      }
    }
    return HomeSummary(
      total: todos.length,
      completed: completed,
      dueToday: dueToday,
      overdue: overdue,
      todayPreview: List.unmodifiable(preview),
    );
  }
}
