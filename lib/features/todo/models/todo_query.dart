import 'todo.dart';

enum TodoSort {
  original,
  titleAscending,
  titleDescending,
  dueAscending,
  dueDescending,
  priorityDescending,
  priorityAscending,
  createdDescending,
  createdAscending,
}

enum TodoDueFilter { overdue, today, withinSevenDays, withinThreeDays }

enum TodoDateField { dueDate, createdAt }

enum TodoDuePresence { all, hasDate, noDate }

class TodoFilter {
  TodoFilter({
    Set<String> priorities = const {},
    Set<TodoDueFilter> dueFilters = const {},
    this.duePresence = TodoDuePresence.all,
    this.dateField = TodoDateField.dueDate,
    DateTime? startDate,
    DateTime? endDate,
  }) : priorities = Set.unmodifiable(priorities),
       dueFilters = Set.unmodifiable(
         duePresence == TodoDuePresence.noDate ? <TodoDueFilter>{} : dueFilters,
       ),
       startDate =
           duePresence == TodoDuePresence.noDate &&
               dateField == TodoDateField.dueDate
           ? null
           : startDate,
       endDate =
           duePresence == TodoDuePresence.noDate &&
               dateField == TodoDateField.dueDate
           ? null
           : endDate,
       assert((startDate == null) == (endDate == null));

  final Set<String> priorities;
  final Set<TodoDueFilter> dueFilters;
  final TodoDuePresence duePresence;
  bool get allowsDueDate => duePresence != TodoDuePresence.noDate;
  final TodoDateField dateField;
  final DateTime? startDate;
  final DateTime? endDate;
  int get count =>
      priorities.length +
      dueFilters.length +
      (duePresence == TodoDuePresence.all ? 0 : 1) +
      (startDate == null ? 0 : 1);
  bool get isActive => count > 0;

  TodoFilter copyWith({
    Set<String>? priorities,
    Set<TodoDueFilter>? dueFilters,
    TodoDuePresence? duePresence,
    TodoDateField? dateField,
    DateTime? startDate,
    DateTime? endDate,
    bool clearRange = false,
  }) => TodoFilter(
    priorities: priorities ?? this.priorities,
    dueFilters: dueFilters ?? this.dueFilters,
    duePresence: duePresence ?? this.duePresence,
    dateField: dateField ?? this.dateField,
    startDate: clearRange ? null : startDate ?? this.startDate,
    endDate: clearRange ? null : endDate ?? this.endDate,
  );
}

// Match the calendar components displayed by the task UI, without DST offsets.
DateTime todoCalendarDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

List<Todo> queryTodos(
  List<Todo> todos, {
  required TodoFilter filter,
  required TodoSort sort,
  required DateTime now,
  String search = '',
}) {
  final today = todoCalendarDay(now);
  final query = search.trim().toLowerCase();
  final matches = todos.indexed.where((entry) {
    final todo = entry.$2;
    if (query.isNotEmpty &&
        !todo.title.toLowerCase().contains(query) &&
        !todo.details.toLowerCase().contains(query)) {
      return false;
    }
    if (filter.priorities.isNotEmpty &&
        !filter.priorities.contains(todo.priority)) {
      return false;
    }
    if (filter.duePresence == TodoDuePresence.hasDate && todo.dueDate == null) {
      return false;
    }
    if (filter.duePresence == TodoDuePresence.noDate && todo.dueDate != null) {
      return false;
    }
    if (filter.dueFilters.isNotEmpty) {
      if (todo.dueDate == null) return false;
      final days = todoCalendarDay(todo.dueDate!).difference(today).inDays;
      final matched = filter.dueFilters.any(
        (value) => switch (value) {
          TodoDueFilter.overdue => days < 0 && !todo.completed,
          TodoDueFilter.today => days == 0,
          TodoDueFilter.withinSevenDays => days >= 0 && days <= 7,
          TodoDueFilter.withinThreeDays => days >= 0 && days <= 3,
        },
      );
      if (!matched) return false;
    }
    if (filter.startDate != null) {
      final date = filter.dateField == TodoDateField.dueDate
          ? todo.dueDate
          : todo.createdAt;
      if (date == null) return false;
      final day = todoCalendarDay(date);
      if (day.isBefore(todoCalendarDay(filter.startDate!)) ||
          day.isAfter(todoCalendarDay(filter.endDate!))) {
        return false;
      }
    }
    return true;
  }).toList();

  int nullableCompare<T extends Comparable<dynamic>>(
    T? a,
    T? b,
    bool descending,
  ) {
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    final result = a.compareTo(b);
    return descending ? -result : result;
  }

  int? rank(String value) => switch (value) {
    'low' => 0,
    'medium' => 1,
    'high' => 2,
    _ => null,
  };
  matches.sort((a, b) {
    final left = a.$2;
    final right = b.$2;
    final result = switch (sort) {
      TodoSort.original => 0,
      TodoSort.titleAscending => left.title.trim().toLowerCase().compareTo(
        right.title.trim().toLowerCase(),
      ),
      TodoSort.titleDescending => right.title.trim().toLowerCase().compareTo(
        left.title.trim().toLowerCase(),
      ),
      TodoSort.dueAscending || TodoSort.dueDescending => nullableCompare(
        left.dueDate == null ? null : todoCalendarDay(left.dueDate!),
        right.dueDate == null ? null : todoCalendarDay(right.dueDate!),
        sort == TodoSort.dueDescending,
      ),
      TodoSort.priorityAscending ||
      TodoSort.priorityDescending => nullableCompare(
        rank(left.priority),
        rank(right.priority),
        sort == TodoSort.priorityDescending,
      ),
      TodoSort.createdAscending ||
      TodoSort.createdDescending => nullableCompare(
        left.createdAt,
        right.createdAt,
        sort == TodoSort.createdDescending,
      ),
    };
    return result == 0 ? a.$1.compareTo(b.$1) : result;
  });
  return matches.map((entry) => entry.$2).toList();
}
