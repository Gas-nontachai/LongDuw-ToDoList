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

  /// Null shows all todos; otherwise filters by completion status.
  final bool? showCompleted;
  final Set<String> busyIds;
  final ValueChanged<Todo> onTodoTap;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<Todo> onEdit;
  final ValueChanged<Todo> onDelete;

  @override
  Widget build(BuildContext context) {
    final filteredTodos = todos
        .where(
          (todo) => showCompleted == null || todo.completed == showCompleted,
        )
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

    final pending = filteredTodos.where((todo) => !todo.completed).toList();
    final completed = filteredTodos.where((todo) => todo.completed).toList();
    final ordered = showCompleted == null
        ? [...pending, ...completed]
        : filteredTodos;
    final sectionIndex = showCompleted == null && completed.isNotEmpty
        ? pending.length
        : -1;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < ordered.length; index++) ...[
                if (index == sectionIndex)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.completed,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  )
                else if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1),
                  ),
                TodoItem(
                  key: ValueKey(ordered[index].id),
                  todo: ordered[index],
                  itemNumber: index + 1,
                  isBusy: busyIds.contains(ordered[index].id),
                  onClick: () => onTodoTap(ordered[index]),
                  onToggle: () => onToggle(ordered[index]),
                  onEdit: () => onEdit(ordered[index]),
                  onDelete: () => onDelete(ordered[index]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
