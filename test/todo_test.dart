import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';

void main() {
  test('Todo converts to and from JSON', () {
    const todo = Todo(
      id: '1',
      title: 'Learn Flutter',
      details: 'Build a todo app',
      completed: false,
    );
    final decoded = Todo.fromJson(todo.toJson());

    expect(decoded.id, '1');
    expect(decoded.title, 'Learn Flutter');
    expect(decoded.completed, isFalse);
    expect(decoded.details, 'Build a todo app');
    expect(todo.copyWith(completed: true).completed, isTrue);
    expect(
      todo.copyWith(details: 'Updated details').details,
      'Updated details',
    );
  });

  test('Todo reads and writes the API schema with ISO dates', () {
    final json = {
      'id': '42',
      'title': 'Company name',
      'completed': true,
      'details': 'Job descriptor',
      'created_at': '2026-10-02T03:00:00.000Z',
      'due_date': '2026-10-05T10:30:00.000Z',
      'priority': 'high',
    };
    final todo = Todo.fromJson(json);

    expect(todo.createdAt, DateTime.utc(2026, 10, 2, 3));
    expect(todo.dueDate, DateTime.utc(2026, 10, 5, 10, 30));
    expect(todo.priority, 'high');
    expect(todo.toJson(), json);

    final edited = todo.copyWith(title: 'Updated', completed: false);
    expect(edited.createdAt, todo.createdAt);
    expect(edited.dueDate, todo.dueDate);
    expect(edited.priority, 'high');

    final rescheduled = todo.copyWith(
      createdAt: DateTime.utc(2026, 10, 3),
      dueDate: DateTime.utc(2026, 10, 6),
      priority: 'low',
    );
    expect(rescheduled.createdAt, DateTime.utc(2026, 10, 3));
    expect(rescheduled.dueDate, DateTime.utc(2026, 10, 6));
    expect(rescheduled.priority, 'low');
  });

  test('Todo supports missing, null, and invalid dates', () {
    for (final json in <Map<String, dynamic>>[
      {},
      {'created_at': null, 'due_date': null, 'priority': null},
      {'created_at': 'invalid', 'due_date': ''},
    ]) {
      final todo = Todo.fromJson(json);
      expect(todo.createdAt, isNull);
      expect(todo.dueDate, isNull);
      expect(todo.priority, isEmpty);
      expect(todo.toJson()['created_at'], isNull);
      expect(todo.toJson()['due_date'], isNull);
    }
  });
}
