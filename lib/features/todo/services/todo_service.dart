import '../../../core/config/priority_config.dart';
import '../../../core/database/app_database.dart';
import '../models/todo.dart';

class TodoService {
  TodoService(this._database);

  final AppDatabase _database;

  Future<List<Todo>> getTodos() => _database.gate.run(() async {
    final db = await _database.database;
    final rows = await db.query('todos', orderBy: 'id ASC');
    return rows.map(Todo.fromDb).toList();
  });

  Future<Todo> getTodoById(String id) => _database.gate.run(() async {
    final db = await _database.database;
    final rows = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Todo $id does not exist.');
    return Todo.fromDb(rows.single);
  });

  Future<Todo> createTodo(
    String title,
    String details, {
    String priority = PriorityConfig.medium,
    DateTime? dueDate,
  }) => _database.gate.run(() async {
    final db = await _database.database;
    final createdAt = DateTime.now().toUtc();
    final id = await db.insert('todos', {
      'title': title,
      'details': details,
      'completed': 0,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
    });
    return Todo(
      id: id.toString(),
      title: title,
      details: details,
      completed: false,
      priority: priority,
      createdAt: createdAt,
      dueDate: dueDate,
    );
  });

  Future<Todo> updateTodo(Todo todo) => _database.gate.run(() async {
    final db = await _database.database;
    // Keep the original creation time even if the caller omits metadata.
    final values = todo.toDb()..remove('created_at');
    final count = await db.update(
      'todos',
      values,
      where: 'id = ?',
      whereArgs: [todo.id],
    );
    if (count == 0) throw StateError('Todo ${todo.id} does not exist.');
    return getTodoById(todo.id);
  });

  Future<void> deleteTodo(String id) => _database.gate.run(() async {
    final db = await _database.database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  });
}
