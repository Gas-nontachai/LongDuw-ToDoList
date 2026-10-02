import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/design/app_icons.dart';
import '../models/todo.dart';

class TodoItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onClick,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$itemNumber',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Checkbox(
              value: todo.completed,
              onChanged: isBusy ? null : (_) => onToggle(),
            ),
          ],
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface,
          ),
        ),
        trailing: isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    tooltip: l10n.editTooltip,
                    icon: const Icon(AppIcons.edit),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: l10n.deleteTooltip,
                    icon: const Icon(AppIcons.delete),
                  ),
                ],
              ),
      ),
    );
  }
}
