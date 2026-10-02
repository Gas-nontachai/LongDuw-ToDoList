import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/todo.dart';
import 'pagination_controls.dart';
import 'todo_item.dart';

class TodoList extends StatefulWidget {
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
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  static const _pageSize = 10;

  var _currentPage = 1;
  String? _itemsSignature;

  String _signature(List<Todo> todos, bool? showCompleted) {
    return [
      showCompleted,
      for (final todo in todos)
        if (showCompleted == null || todo.completed == showCompleted)
          '${todo.id}:${todo.completed}:${todo.title}:${todo.details}',
    ].join('|');
  }

  @override
  void didUpdateWidget(covariant TodoList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSignature = _signature(oldWidget.todos, oldWidget.showCompleted);
    final newSignature = _signature(widget.todos, widget.showCompleted);
    if (oldSignature != newSignature) {
      _currentPage = 1;
      _itemsSignature = newSignature;
    }
  }

  void _goToPage(int page, int pageCount) {
    if (page < 1 || page > pageCount || page == _currentPage) return;
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final signature = _signature(widget.todos, widget.showCompleted);
    if (_itemsSignature != signature) {
      _itemsSignature = signature;
    }

    final filteredTodos = widget.todos
        .where(
          (todo) =>
              widget.showCompleted == null ||
              todo.completed == widget.showCompleted,
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

    final pageCount = (filteredTodos.length + _pageSize - 1) ~/ _pageSize;
    final safePage = _currentPage > pageCount ? pageCount : _currentPage;
    final startIndex = (safePage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize > filteredTodos.length
        ? filteredTodos.length
        : startIndex + _pageSize;
    final pageTodos = filteredTodos.sublist(startIndex, endIndex);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: pageTodos.length,
            itemBuilder: (context, index) {
              final todo = pageTodos[index];
              return TodoItem(
                todo: todo,
                itemNumber: startIndex + index + 1,
                isBusy: widget.busyIds.contains(todo.id),
                onClick: () => widget.onTodoTap(todo),
                onToggle: () => widget.onToggle(todo),
                onEdit: () => widget.onEdit(todo),
                onDelete: () => widget.onDelete(todo),
              );
            },
          ),
        ),
        const Divider(height: 1),
        PaginationControls(
          currentPage: safePage,
          pageCount: pageCount,
          onPageChanged: (page) => _goToPage(page, pageCount),
        ),
      ],
    );
  }
}
