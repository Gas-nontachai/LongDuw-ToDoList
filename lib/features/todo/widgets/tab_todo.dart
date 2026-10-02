import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_tab_bar.dart';
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
    this.controller,
    this.hasQuery = false,
    super.key,
  });

  final TabController? controller;
  final List<Todo> todos;
  final bool hasQuery;
  final Set<String> busyIds;
  final ValueChanged<Todo> onTodoTap;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<Todo> onEdit;
  final ValueChanged<Todo> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                final controller =
                    this.controller ?? DefaultTabController.of(context);
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) => AppTabBar(
                    tabs: [l10n.all, l10n.incomplete, l10n.completed],
                    selectedIndex: controller.index,
                    onChanged: (index) => controller.animateTo(
                      index,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: [
                TodoList(
                  todos: todos,
                  hasQuery: hasQuery,
                  showCompleted: null,
                  busyIds: busyIds,
                  onTodoTap: onTodoTap,
                  onToggle: onToggle,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
                TodoList(
                  todos: todos,
                  hasQuery: hasQuery,
                  showCompleted: false,
                  busyIds: busyIds,
                  onTodoTap: onTodoTap,
                  onToggle: onToggle,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
                TodoList(
                  todos: todos,
                  hasQuery: hasQuery,
                  showCompleted: true,
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
