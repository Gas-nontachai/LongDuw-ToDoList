import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../core/config/priority_config.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design/app_icons.dart';
import '../models/todo.dart';
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
    super.key,
  });
  final Todo todo;
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
    return MenuAnchor(
      onOpen: () => setState(() => _menuOpen = true),
      onClose: () => setState(() => _menuOpen = false),
      style: MenuStyle(
        alignment: Alignment.topRight,
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        elevation: const WidgetStatePropertyAll(12),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(CupertinoIcons.eye),
          onPressed: widget.onClick,
          child: Text(l10n.viewTodo),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.edit),
          onPressed: widget.onEdit,
          child: Text(l10n.editTooltip),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: Icon(AppIcons.delete, color: colors.error),
          onPressed: widget.onDelete,
          child: Text(
            l10n.deleteTooltip,
            style: TextStyle(color: colors.error),
          ),
        ),
      ],
      builder: (context, controller, child) => Material(
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
                          Icon(CupertinoIcons.clock, size: 16, color: muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              todo.dueDate == null
                                  ? l10n.notSpecified
                                  : DateTimeUtils.formatDate(
                                      todo.dueDate,
                                      localizations: MaterialLocalizations.of(
                                        context,
                                      ),
                                    ),
                              style: TextStyle(color: muted, fontSize: 14),
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
                  onPressed: widget.isBusy
                      ? null
                      : () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
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
