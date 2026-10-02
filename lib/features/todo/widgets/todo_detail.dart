import 'package:flutter/material.dart';

import '../../../core/config/priority_config.dart';
import '../../../core/config/dialog_config.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design/app_icon_assets.dart';
import '../../../shared/widgets/app_icon.dart';
import '../models/todo.dart';
import 'todo_priority_badge.dart';

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
    final colors = theme.colorScheme;
    final materialL10n = MaterialLocalizations.of(context);
    final createdAt = todo.createdAt?.toLocal();
    final createdAtText = createdAt == null
        ? l10n.notSpecified
        : '${DateTimeUtils.formatDate(createdAt, localizations: materialL10n)} '
              '${materialL10n.formatTimeOfDay(TimeOfDay.fromDateTime(createdAt), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    Widget textValue(String value, {TextStyle? style}) => SelectableText(
      value.trim().isEmpty ? l10n.notSpecified : value,
      style: style ?? theme.textTheme.bodyLarge,
    );

    Widget field(String label, Widget value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        value,
      ],
    );

    Widget dateField(IconData icon, String label, String value) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(child: field(label, textValue(value))),
      ],
    );

    final status = Semantics(
      label:
          '${l10n.status}: ${todo.completed ? l10n.completed : l10n.incomplete}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: todo.completed
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          todo.completed ? l10n.completed : l10n.incomplete,
          style: theme.textTheme.labelMedium?.copyWith(
            color: todo.completed
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    final dueDate = dateField(
      Icons.calendar_month_outlined,
      l10n.dueDate,
      DateTimeUtils.formatDate(todo.dueDate, localizations: materialL10n),
    );
    final createdDate = dateField(
      Icons.schedule_outlined,
      l10n.createdAt,
      createdAtText,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final dialogWidth = constraints.maxWidth * DialogConfig.widthFactor;
        final useDateColumns =
            dialogWidth >= 520 &&
            MediaQuery.textScalerOf(context).scale(16) <= 22;
        return AlertDialog(
          constraints: BoxConstraints.tightFor(width: dialogWidth),
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: colors.surfaceContainerLow,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcon.asset(AppIconAssets.task, size: 28),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              l10n.details,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          status,
                          if (PriorityConfig.values.contains(todo.priority))
                            TodoPriorityBadge(priority: todo.priority)
                          else
                            Text(
                              '${l10n.priority}: ${todo.priority.isEmpty ? l10n.notSpecified : todo.priority}',
                              style: labelStyle,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                field(
                  l10n.title,
                  textValue(
                    todo.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                field(l10n.details, textValue(todo.details)),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),
                if (useDateColumns)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: dueDate),
                        const VerticalDivider(width: 32),
                        Expanded(child: createdDate),
                      ],
                    ),
                  )
                else ...[
                  dueDate,
                  const SizedBox(height: 20),
                  createdDate,
                ],
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(112, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(materialL10n.closeButtonLabel),
            ),
          ],
        );
      },
    );
  }
}
