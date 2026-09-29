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
}
