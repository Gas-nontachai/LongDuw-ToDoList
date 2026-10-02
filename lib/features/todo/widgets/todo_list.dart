import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/todo.dart';
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
    this.now,
    this.hasQuery = false,
    super.key,
  });

  final List<Todo> todos;
  final bool hasQuery;

  /// Null shows all todos; otherwise filters by completion status.
  final bool? showCompleted;
  final Set<String> busyIds;
  final ValueChanged<Todo> onTodoTap;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<Todo> onEdit;
  final ValueChanged<Todo> onDelete;

  /// Optional clock for deterministic calendar rollover tests.
  final DateTime Function()? now;

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> with WidgetsBindingObserver {
  Timer? _midnightTimer;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = _now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextDay.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _midnightTimer?.cancel();
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleMidnight();
    }
  }

  @override
  void didUpdateWidget(covariant TodoList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.now != widget.now) _scheduleMidnight();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = _now();
    final showCompleted = widget.showCompleted;
    final filteredTodos = widget.todos
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
              child: Text(
                widget.hasQuery
                    ? AppLocalizations.of(context)!.noMatchingTodos
                    : AppLocalizations.of(context)!.noTodosYet,
              ),
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
                  currentDate: today,
                  isBusy: widget.busyIds.contains(ordered[index].id),
                  onClick: () => widget.onTodoTap(ordered[index]),
                  onToggle: () => widget.onToggle(ordered[index]),
                  onEdit: () => widget.onEdit(ordered[index]),
                  onDelete: () => widget.onDelete(ordered[index]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
