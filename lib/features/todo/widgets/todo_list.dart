import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/todo.dart';
import 'todo_item.dart';

class TodoList extends StatelessWidget {
  const TodoList({
    required this.todos,
    required this.showCompleted,
    required this.busyIds,
    required this.onTodoTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<Todo> todos;
  final bool showCompleted;
  final Set<String> busyIds;
  final ValueChanged<Todo> onTodoTap;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<Todo> onEdit;
  final ValueChanged<Todo> onDelete;

  @override
  Widget build(BuildContext context) {
    final filteredTodos = todos
        .where((todo) => todo.completed == showCompleted)
        .toList();

    if (filteredTodos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: Text(AppLocalizations.of(context)!.noTodosYet),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: filteredTodos.length,
      itemBuilder: (context, index) {
        final todo = filteredTodos[index];
        return TodoItem(
          todo: todo,
          isBusy: busyIds.contains(todo.id),
          onClick: () => onTodoTap(todo),
          onToggle: () => onToggle(todo),
          onEdit: () => onEdit(todo),
          onDelete: () => onDelete(todo),
        );
      },
    );
  }
}
