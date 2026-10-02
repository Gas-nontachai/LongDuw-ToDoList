import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../core/config/priority_config.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../models/todo.dart';
import '../models/todo_due_status.dart';
import 'todo_actions_menu.dart';
import 'todo_priority_badge.dart';

class TodoItem extends StatefulWidget {
  const TodoItem({
    required this.onClick,
    required this.todo,
    required this.itemNumber,
    required this.isBusy,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.currentDate,
    super.key,
  });
  final Todo todo;
  final DateTime? currentDate;
  final int itemNumber;
  final bool isBusy;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClick;

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dueInfo = TodoDueInfo.calculate(
      dueDate: todo.dueDate,
      completed: todo.completed,
      today: widget.currentDate ?? DateTime.now(),
    );
    final days = dueInfo.daysRemaining;
    final dueColor = switch (dueInfo.status) {
      TodoDueStatus.overdue =>
        isDark ? const Color(0xFFFF6B6B) : const Color(0xFFB71C1C),
      TodoDueStatus.dueSoon =>
        days == 0
            ? colors.error
            : isDark
            ? const Color(0xFFFFD166)
            : const Color(0xFF956000),
      _ => muted,
    };
    final remainingLabel = days == null || days > 3
        ? null
        : days < 0
        ? l10n.overdueDays(-days)
        : days == 0
        ? l10n.dueToday
        : l10n.daysRemaining(days);
    final dateLabel = todo.dueDate == null
        ? l10n.notSpecified
        : DateTimeUtils.formatDate(
            todo.dueDate,
            localizations: MaterialLocalizations.of(context),
          );
    final dueLabel = remainingLabel == null
        ? dateLabel
        : '$dateLabel · $remainingLabel';
    return TodoActionsMenu(
      enabled: !widget.isBusy,
      onView: widget.onClick,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      onOpen: () => setState(() => _menuOpen = true),
      onClose: () => setState(() => _menuOpen = false),
      builder: (context, toggleMenu) => Material(
        color: _menuOpen ? colors.surfaceContainerLow : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.isBusy ? null : widget.onClick,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.4,
                  child: Checkbox(
                    value: todo.completed,
                    shape: const CircleBorder(),
                    activeColor: const Color(0xFF10A566),
                    side: BorderSide(color: muted, width: 1.6),
                    onChanged: widget.isBusy ? null : (_) => widget.onToggle(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 18,
                              decoration: todo.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.completed ? muted : colors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(CupertinoIcons.clock, size: 16, color: dueColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dueLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: dueColor, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (PriorityConfig.values.contains(todo.priority)) ...[
                  const SizedBox(width: 12),
                  TodoPriorityBadge(priority: todo.priority, compact: true),
                ],
                IconButton(
                  tooltip: l10n.moreActions,
                  icon: const Icon(Icons.more_vert),
                  color: muted,
                  onPressed: toggleMenu,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
