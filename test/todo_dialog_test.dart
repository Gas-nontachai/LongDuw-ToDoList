import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/app.dart';
import 'package:my_first_flutter_app/core/api/api_client.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/providers/todo_provider.dart';
import 'package:my_first_flutter_app/features/todo/services/todo_service.dart';

class FakeTodoService extends TodoService {
  FakeTodoService() : super(ApiClient());

  @override
  Future<List<Todo>> getTodos() async => const [];

  @override
  Future<Todo> createTodo(String title) async =>
      Todo(id: '1', title: title, completed: false);
}

void main() {
  testWidgets('saving the add dialog keeps the widget tree valid', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoServiceProvider.overrideWithValue(FakeTodoService())],
        child: TodoApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Add todo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Test todo');
    await tester.tap(find.widgetWithText(FilledButton, 'Add todo'));
    await tester.pumpAndSettle();

    expect(find.text('Test todo'), findsOneWidget);
  });
}
