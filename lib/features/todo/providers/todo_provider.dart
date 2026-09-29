import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final todoServiceProvider = Provider<TodoService>(
  (ref) => TodoService(ref.watch(apiClientProvider)),
);

class TodoOperationState {
  const TodoOperationState({this.busyIds = const {}, this.isCreating = false});
  final Set<String> busyIds;
  final bool isCreating;
  TodoOperationState copyWith({Set<String>? busyIds, bool? isCreating}) =>
      TodoOperationState(
        busyIds: busyIds ?? this.busyIds,
        isCreating: isCreating ?? this.isCreating,
      );
}

class TodoOperationNotifier extends Notifier<TodoOperationState> {
  @override
  TodoOperationState build() => const TodoOperationState();

  void setBusy(String id, bool value) {
    final ids = {...state.busyIds};
    value ? ids.add(id) : ids.remove(id);
    state = state.copyWith(busyIds: ids);
  }

  void setCreating(bool value) => state = state.copyWith(isCreating: value);
}

final todoOperationProvider =
    NotifierProvider<TodoOperationNotifier, TodoOperationState>(
      TodoOperationNotifier.new,
    );

class TodoNotifier extends AsyncNotifier<List<Todo>> {
  TodoService get _service => ref.read(todoServiceProvider);

  @override
  Future<List<Todo>> build() => _service.getTodos();

  Future<void> refreshTodos() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_service.getTodos);
  }

  Future<void> addTodo(String title) async {
    final operations = ref.read(todoOperationProvider.notifier);
    operations.setCreating(true);
    try {
      final created = await _service.createTodo(title);
      state = AsyncData([...state.value ?? [], created]);
    } finally {
      operations.setCreating(false);
    }
  }

  Future<void> toggleTodo(Todo todo) =>
      updateTodo(todo.copyWith(completed: !todo.completed));

  Future<void> updateTodo(Todo todo) async {
    final operations = ref.read(todoOperationProvider.notifier);
    operations.setBusy(todo.id, true);
    try {
      final updated = await _service.updateTodo(todo);
      final todos = [...state.value ?? <Todo>[]];
      final index = todos.indexWhere((item) => item.id == todo.id);
      if (index != -1) todos[index] = updated;
      state = AsyncData(todos);
    } finally {
      operations.setBusy(todo.id, false);
    }
  }

  Future<void> deleteTodo(Todo todo) async {
    final operations = ref.read(todoOperationProvider.notifier);
    operations.setBusy(todo.id, true);
    try {
      await _service.deleteTodo(todo.id);
      state = AsyncData(
        (state.value ?? <Todo>[]).where((item) => item.id != todo.id).toList(),
      );
    } finally {
      operations.setBusy(todo.id, false);
    }
  }
}

final todoProvider = AsyncNotifierProvider<TodoNotifier, List<Todo>>(
  TodoNotifier.new,
);
