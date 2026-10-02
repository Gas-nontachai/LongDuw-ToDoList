import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/models/todo_query.dart';

void main() {
  final now = DateTime(2026, 10, 2, 12);
  Todo task(
    String id, {
    int? day,
    String priority = 'medium',
    bool completed = false,
    DateTime? createdAt,
    String? title,
  }) => Todo(
    id: id,
    title: title ?? id,
    details: 'details $id',
    completed: completed,
    priority: priority,
    dueDate: day == null ? null : DateTime(2026, 10, day, 23),
    createdAt: createdAt,
  );
  final todos = [
    task('overdue', day: 1, priority: 'high'),
    task('finished', day: 1, priority: 'high', completed: true),
    task('today', day: 2, priority: 'low'),
    task('three', day: 5, priority: 'high'),
    task('seven', day: 9),
    task('later', day: 10),
    task('undated', priority: ''),
  ];
  List<String> ids(
    TodoFilter filter, {
    DateTime? today,
    String search = '',
    TodoSort sort = TodoSort.original,
    List<Todo>? items,
  }) => queryTodos(
    items ?? todos,
    filter: filter,
    sort: sort,
    now: today ?? now,
    search: search,
  ).map((todo) => todo.id).toList();

  test('due windows include boundaries and exclude overdue', () {
    expect(ids(TodoFilter(dueFilters: {TodoDueFilter.overdue})), ['overdue']);
    expect(ids(TodoFilter(dueFilters: {TodoDueFilter.today})), ['today']);
    expect(ids(TodoFilter(dueFilters: {TodoDueFilter.withinThreeDays})), [
      'today',
      'three',
    ]);
    expect(ids(TodoFilter(dueFilters: {TodoDueFilter.withinSevenDays})), [
      'today',
      'three',
      'seven',
    ]);
    expect(
      ids(TodoFilter(dueFilters: {TodoDueFilter.overdue, TodoDueFilter.today})),
      ['overdue', 'today'],
    );
  });
  test('OR within categories, AND between categories and search', () {
    final filter = TodoFilter(
      priorities: {'high', 'low'},
      dueFilters: {TodoDueFilter.withinSevenDays},
      duePresence: TodoDuePresence.hasDate,
    );
    expect(ids(filter), ['today', 'three']);
    expect(ids(filter, search: 'DETAILS three'), ['three']);
    expect(ids(filter.copyWith(duePresence: TodoDuePresence.noDate)), isEmpty);
    expect(
      ids(TodoFilter(duePresence: TodoDuePresence.all)),
      todos.map((todo) => todo.id),
    );
  });
  test('date ranges are inclusive calendar dates and reject missing dates', () {
    final filter = TodoFilter(
      startDate: DateTime(2026, 10, 2),
      endDate: DateTime(2026, 10, 5),
    );
    expect(ids(filter), ['today', 'three']);
    final items = [
      task('start', createdAt: DateTime(2026, 10, 2, 1)),
      task('end', createdAt: DateTime(2026, 10, 5, 23, 59)),
      task('missing'),
      task('outside', createdAt: DateTime(2026, 10, 6)),
    ];
    expect(
      ids(filter.copyWith(dateField: TodoDateField.createdAt), items: items),
      ['start', 'end'],
    );
    expect(filter.copyWith(clearRange: true).count, 0);
  });
  test('date filters recalculate on the next day', () {
    expect(
      ids(
        TodoFilter(dueFilters: {TodoDueFilter.today}),
        today: DateTime(2026, 10, 5),
      ),
      ['three'],
    );
    expect(
      ids(
        TodoFilter(dueFilters: {TodoDueFilter.overdue}),
        today: DateTime(2026, 10, 3),
      ),
      ['overdue', 'today'],
    );
  });
  test('sorts are stable, nulls last in both directions, input unchanged', () {
    final items = [
      task(
        'b',
        day: 5,
        priority: 'low',
        title: ' beta ',
        createdAt: DateTime(2026, 10, 5),
      ),
      task(
        'a',
        day: 2,
        priority: 'high',
        title: 'Alpha',
        createdAt: DateTime(2026, 10, 2),
      ),
      task(
        'tie',
        day: 2,
        priority: 'high',
        title: 'alpha',
        createdAt: DateTime(2026, 10, 2),
      ),
      task('missing', priority: 'unknown', title: 'Z'),
    ];
    final expected = {
      TodoSort.original: ['b', 'a', 'tie', 'missing'],
      TodoSort.titleAscending: ['a', 'tie', 'b', 'missing'],
      TodoSort.titleDescending: ['missing', 'b', 'a', 'tie'],
      TodoSort.dueAscending: ['a', 'tie', 'b', 'missing'],
      TodoSort.dueDescending: ['b', 'a', 'tie', 'missing'],
      TodoSort.priorityDescending: ['a', 'tie', 'b', 'missing'],
      TodoSort.priorityAscending: ['b', 'a', 'tie', 'missing'],
      TodoSort.createdDescending: ['b', 'a', 'tie', 'missing'],
      TodoSort.createdAscending: ['a', 'tie', 'b', 'missing'],
    };
    for (final sort in TodoSort.values) {
      expect(
        ids(TodoFilter(), items: items, sort: sort),
        expected[sort],
        reason: '$sort',
      );
    }
    expect(items.map((todo) => todo.id), ['b', 'a', 'tie', 'missing']);
  });
  test('filter state owns immutable sets and counts selected conditions', () {
    final priorities = {'high'};
    final filter = TodoFilter(
      priorities: priorities,
      dueFilters: {TodoDueFilter.today},
      duePresence: TodoDuePresence.all,
      startDate: now,
      endDate: now,
    );
    priorities.clear();
    expect(filter.priorities, {'high'});
    expect(filter.count, 3);
    expect(() => filter.priorities.add('low'), throwsUnsupportedError);
  });
  test('no due date clears incompatible filters and keeps created range', () {
    final filter = TodoFilter(
      priorities: {'high'},
      duePresence: TodoDuePresence.hasDate,
      dueFilters: {TodoDueFilter.today, TodoDueFilter.overdue},
      startDate: now,
      endDate: now,
    );
    final undated = filter.copyWith(duePresence: TodoDuePresence.noDate);
    expect(undated.dueFilters, isEmpty);
    expect(undated.startDate, isNull);
    expect(undated.endDate, isNull);
    expect(undated.priorities, {'high'});
    expect(undated.count, 2);
    final enabled = undated.copyWith(duePresence: TodoDuePresence.all);
    expect(enabled.allowsDueDate, isTrue);
    expect(enabled.dueFilters, isEmpty);
    expect(enabled.startDate, isNull);
    final created = filter
        .copyWith(dateField: TodoDateField.createdAt)
        .copyWith(duePresence: TodoDuePresence.noDate);
    expect(created.startDate, now);
    expect(created.endDate, now);
    expect(created.dueFilters, isEmpty);
    expect(ids(TodoFilter(duePresence: TodoDuePresence.noDate)), ['undated']);
    expect(ids(TodoFilter(duePresence: TodoDuePresence.hasDate)), [
      'overdue',
      'finished',
      'today',
      'three',
      'seven',
      'later',
    ]);
    expect(
      TodoFilter(
        duePresence: TodoDuePresence.noDate,
        dueFilters: {TodoDueFilter.today},
        startDate: now,
        endDate: now,
      ).count,
      1,
    );
  });
}
