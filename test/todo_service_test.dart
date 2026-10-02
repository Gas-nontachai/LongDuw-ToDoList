import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/core/api/api_client.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/services/todo_service.dart';

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(dio: Dio());

  String? path;
  Map<String, dynamic>? payload;

  Response<dynamic> _respond(String path, Object? data) {
    this.path = path;
    payload = Map<String, dynamic>.from(data! as Map);
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'id': '1', ...payload!},
    );
  }

  @override
  Future<Response<dynamic>> post(String path, {Object? data}) async =>
      _respond(path, data);

  @override
  Future<Response<dynamic>> put(String path, {Object? data}) async =>
      _respond(path, data);
}

void main() {
  test('create sends priority and an ISO due date to the API', () async {
    final client = _RecordingApiClient();
    final service = TodoService(client);
    final dueDate = DateTime.utc(2026, 10, 5);

    final created = await service.createTodo(
      'Title',
      'Details',
      priority: 'high',
      dueDate: dueDate,
    );

    expect(client.path, '/todos');
    expect(client.payload, {
      'title': 'Title',
      'details': 'Details',
      'completed': false,
      'priority': 'high',
      'due_date': '2026-10-05T00:00:00.000Z',
    });
    expect(created.priority, 'high');
    expect(created.dueDate, dueDate);

    await service.createTodo('Title', 'Details');
    expect(client.payload!['priority'], 'medium');
    expect(client.payload!['due_date'], isNull);
  });

  test('edit clears the due date and preserves server metadata', () async {
    final client = _RecordingApiClient();
    final service = TodoService(client);
    final todo = Todo(
      id: '1',
      title: 'Title',
      details: 'Details',
      completed: true,
      createdAt: DateTime.utc(2026, 10, 2, 3),
      dueDate: DateTime.utc(2026, 10, 5),
      priority: 'low',
    );

    final updated = await service.updateTodo(
      todo.copyWith(priority: 'high', clearDueDate: true),
    );

    expect(client.path, '/todos/1');
    expect(client.payload!['priority'], 'high');
    expect(client.payload!['due_date'], isNull);
    expect(client.payload!['created_at'], '2026-10-02T03:00:00.000Z');
    expect(updated.completed, isTrue);
    expect(updated.createdAt, todo.createdAt);
    expect(updated.dueDate, isNull);
  });
}
