import 'package:flutter/material.dart';

import '../../../core/config/priority_config.dart';
import '../../../l10n/app_localizations.dart';
import 'todo_priority_badge.dart';

/// The same task fields for the normal form and the guided first-task form.
/// The parent owns the draft, date picker and save operation.
class TodoFormFields extends StatelessWidget {
  const TodoFormFields({
    super.key,
    required this.titleController,
    required this.detailsController,
    required this.dueDateController,
    required this.priority,
    required this.dueDate,
    required this.onPriorityChanged,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.onSubmit,
    this.enabled = true,
    this.titleFieldKey,
    this.titleHint,
  });

  final TextEditingController titleController;
  final TextEditingController detailsController;
  final TextEditingController dueDateController;
  final String priority;
  final DateTime? dueDate;
  final ValueChanged<String> onPriorityChanged;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;
  final VoidCallback onSubmit;
  final bool enabled;
  final Key? titleFieldKey;
  final String? titleHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          key: titleFieldKey,
          controller: titleController,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            labelText: l10n.title,
            hintText: titleHint,
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? l10n.enterTitle : null,
          onFieldSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: detailsController,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.details),
          onFieldSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          // Keep controlled priority changes (e.g. back navigation) in sync.
          key: ValueKey(priority),
          initialValue: priority,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.priority),
          items: [
            for (final value in PriorityConfig.values)
              DropdownMenuItem(
                value: value,
                child: TodoPriorityBadge(priority: value),
              ),
          ],
          onChanged: !enabled
              ? null
              : (value) {
                  if (value != null) onPriorityChanged(value);
                },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: dueDateController,
          enabled: enabled,
          readOnly: true,
          onTap: onPickDueDate,
          decoration: InputDecoration(
            labelText: l10n.dueDate,
            hintText: l10n.selectDueDate,
            suffixIcon: dueDate == null
                ? const Icon(Icons.calendar_today_outlined)
                : IconButton(
                    tooltip: l10n.clearDueDate,
                    icon: const Icon(Icons.clear),
                    onPressed: enabled ? onClearDueDate : null,
                  ),
          ),
        ),
      ],
    );
  }
}
