import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/todo.dart';

Future<void> showTodoDetail(BuildContext context, {required Todo todo}) {
  return showDialog<void>(
    context: context,
    builder: (_) => TodoDetailDialog(todo: todo),
  );
}

class TodoDetailDialog extends StatelessWidget {
  const TodoDetailDialog({required this.todo, super.key});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusText = todo.completed ? l10n.completed : l10n.incomplete;
    final statusColor = todo.completed
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return AlertDialog(
      title: Text(todo.title, style: theme.textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.status}: $statusText',
                style: theme.textTheme.bodyLarge?.copyWith(color: statusColor),
              ),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
