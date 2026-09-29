import '../../../core/api/api_client.dart';
import '../models/todo.dart';

class TodoService {
  TodoService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Todo>> getTodos() async {
    final response = await _apiClient.get('/todos');
    if (response.data is! List) {
      throw const FormatException('The API returned an invalid todo list.');
    }
    return (response.data as List)
        .whereType<Map>()
        .map((json) => Todo.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

 Future<Todo> getTodoById(String id) async {
    final response = await _apiClient.get('/todos/$id');
    if (response.data is! Map) {
      throw const FormatException('The API returned an invalid todo.');
    }
    return Todo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Todo> createTodo(String title) async {
    final response = await _apiClient.post(
      '/todos',
      data: {'title': title, 'completed': false},
    );
    return Todo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Todo> updateTodo(Todo todo) async {
    final response = await _apiClient.put(
      '/todos/${todo.id}',
      data: todo.toJson(),
    );
    return Todo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteTodo(String id) async {
    await _apiClient.delete('/todos/$id');
  }
}
