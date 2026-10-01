import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/todo.dart';
import 'todo_list.dart';

class TabBarTodo extends StatelessWidget {
  const TabBarTodo({
    required this.todos,
    required this.busyIds,
    required this.onTodoTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<Todo> todos;
  final Set<String> busyIds;
  final ValueChanged<Todo> onTodoTap;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<Todo> onEdit;
  final ValueChanged<Todo> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      initialIndex: 1,
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                Tab(icon: const Icon(Icons.check), text: l10n.completed),
                Tab(icon: const Icon(Icons.close), text: l10n.incomplete),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                TodoList(
                  todos: todos,
                  showCompleted: true,
                  busyIds: busyIds,
                  onTodoTap: onTodoTap,
                  onToggle: onToggle,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
                TodoList(
                  todos: todos,
                  showCompleted: false,
                  busyIds: busyIds,
                  onTodoTap: onTodoTap,
                  onToggle: onToggle,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
