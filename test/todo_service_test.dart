import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/core/database/app_database.dart';
import 'package:longdow_todo_list/features/todo/models/todo.dart';
import 'package:longdow_todo_list/features/todo/providers/todo_provider.dart';
import 'package:longdow_todo_list/features/todo/services/todo_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String path;
  late AppDatabase database;
  late TodoService service;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('todo_sqlite_test_');
    path = p.join(directory.path, 'todos.db');
    database = AppDatabase(factory: databaseFactoryFfi, path: path);
    service = TodoService(database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('creates the schema once and starts with an empty list', () async {
    final connections = await Future.wait([
      database.database,
      database.database,
    ]);
    expect(identical(connections[0], connections[1]), isTrue);
    expect(await connections.first.getVersion(), AppDatabase.schemaVersion);
    expect(await service.getTodos(), isEmpty);
  });

  test('create stores dates, defaults, Thai text and unique IDs', () async {
    final dueDate = DateTime.utc(2026, 10, 5);
    final created = await service.createTodo(
      "งาน 'สำคัญ'",
      'รายละเอียด',
      priority: 'high',
      dueDate: dueDate,
    );
    final other = await service.createTodo('Second', '');
    final loaded = await service.getTodoById(created.id);

    expect(loaded.toJson(), created.toJson());
    expect(loaded.completed, isFalse);
    expect(loaded.createdAt, isNotNull);
    expect(loaded.dueDate, dueDate);
    expect(other.id, isNot(created.id));
    expect(other.priority, 'medium');
    expect(other.dueDate, isNull);
    expect((await service.getTodos()).map((todo) => todo.id), [
      created.id,
      other.id,
    ]);
  });

  test('edit persists completion and clears dates, preserving creation time', () async {
    final created = await service.createTodo(
      'Title',
      'Details',
      dueDate: DateTime.utc(2026, 10, 5),
    );
    final updated = await service.updateTodo(
      created.copyWith(
        title: 'Edited',
        details: 'New details',
        priority: 'high',
        completed: true,
        clearDueDate: true,
      ),
    );
    expect(updated.title, 'Edited');
    expect(updated.details, 'New details');
    expect(updated.priority, 'high');
    expect(updated.completed, isTrue);
    expect(updated.createdAt, created.createdAt);
    expect(updated.dueDate, isNull);
    expect((await service.getTodoById(created.id)).toJson(), updated.toJson());

    // A caller constructing a Todo without metadata must not erase created_at.
    final withoutMetadata = await service.updateTodo(
      Todo(
        id: created.id,
        title: 'Minimal edit',
        details: '',
        completed: false,
      ),
    );
    expect(withoutMetadata.createdAt, created.createdAt);
    expect(withoutMetadata.completed, isFalse);
  });

  test(
    'delete affects only the selected row and never reuses its ID',
    () async {
      final first = await service.createTodo('First', '');
      final second = await service.createTodo('Second', '');
      await service.deleteTodo(second.id);
      await service.deleteTodo(second.id);
      final third = await service.createTodo('Third', '');
      expect(third.id, isNot(second.id));
      expect((await service.getTodos()).map((todo) => todo.id), [
        first.id,
        third.id,
      ]);
      await expectLater(service.getTodoById(second.id), throwsStateError);
      await expectLater(service.updateTodo(second), throwsStateError);
      // IDs are bound parameters, not SQL text.
      await service.deleteTodo('1 OR 1 = 1');
      expect(await service.getTodos(), hasLength(2));
    },
  );

  test('data and edits survive closing and reopening the database', () async {
    final created = await service.createTodo('Persistent', 'Details');
    final updated = await service.updateTodo(created.copyWith(completed: true));
    final deleted = await service.createTodo('Deleted', '');
    await service.deleteTodo(deleted.id);
    await database.close();
    database = AppDatabase(factory: databaseFactoryFfi, path: path);
    service = TodoService(database);
    final rows = await service.getTodos();
    expect(rows, hasLength(1));
    expect(rows.single.toJson(), updated.toJson());
  });

  test(
    'provider reads, adds, toggles, edits and deletes using SQLite',
    () async {
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);
      expect(await container.read(todoProvider.future), isEmpty);
      final notifier = container.read(todoProvider.notifier);
      await notifier.addTodo('Offline', 'Details');
      var todo = container.read(todoProvider).requireValue.single;
      await notifier.toggleTodo(todo);
      todo = container.read(todoProvider).requireValue.single;
      expect(todo.completed, isTrue);
      await notifier.updateTodo(todo.copyWith(title: 'Edited'));
      await notifier.refreshTodos();
      expect(container.read(todoProvider).requireValue.single.title, 'Edited');
      await notifier.deleteTodo(todo);
      expect(container.read(todoProvider).requireValue, isEmpty);
      expect(await service.getTodos(), isEmpty);
      expect(container.read(todoOperationProvider).busyIds, isEmpty);
      expect(container.read(todoOperationProvider).isCreating, isFalse);
    },
  );
}
