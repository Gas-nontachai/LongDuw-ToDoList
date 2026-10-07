import 'package:sqflite/sqflite.dart';

import '../../../app/app_preferences.dart';
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
    return _insertTodo(
      db,
      title,
      details,
      priority: priority,
      dueDate: dueDate,
    );
  });

  /// Commits the first task and onboarding completion together.
  Future<Todo> createOnboardingTodo(
    String title, {
    String details = '',
    String priority = PriorityConfig.medium,
    DateTime? dueDate,
  }) => _database.gate.run(() async {
    final db = await _database.database;
    return db.transaction((txn) async {
      final state = await txn.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [AppPreferences.onboardingCompletedKey],
      );
      if (state.any((row) => row['value'] == 'true')) {
        throw StateError('Onboarding has already completed.');
      }
      final todo = await _insertTodo(
        txn,
        title,
        details,
        priority: priority,
        dueDate: dueDate,
      );
      await txn.insert('app_metadata', {
        'key': AppPreferences.onboardingCompletedKey,
        'value': 'true',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return todo;
    });
  });

  Future<Todo> _insertTodo(
    DatabaseExecutor db,
    String title,
    String details, {
    required String priority,
    DateTime? dueDate,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) throw ArgumentError.value(title, 'title');
    if (!PriorityConfig.values.contains(priority)) {
      throw ArgumentError.value(priority, 'priority');
    }
    final createdAt = DateTime.now().toUtc();
    final id = await db.insert('todos', {
      'title': trimmedTitle,
      'details': details,
      'completed': 0,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
    });
    return Todo(
      id: '$id',
      title: trimmedTitle,
      details: details,
      completed: false,
      priority: priority,
      createdAt: createdAt,
      dueDate: dueDate,
    );
  }

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
