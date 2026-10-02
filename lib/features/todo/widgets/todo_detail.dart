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

    Widget dateField(
      IconData icon,
      String label,
      String value, {
      required bool compact,
      required double scale,
    }) {
      final dateIcon = Icon(
        icon,
        size: 18 * scale,
        color: colors.onSurfaceVariant,
      );
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12 * scale,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          textValue(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13 * scale,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      );
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [dateIcon, const SizedBox(height: 6), content],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: dateIcon),
          const SizedBox(width: 8),
          Expanded(child: content),
        ],
      );
    }

    final statusLabel = todo.completed ? l10n.completed : l10n.incomplete;
    final statusDescription = '${l10n.status}: $statusLabel';
    final statusStyle = theme.textTheme.labelMedium?.copyWith(
      color: todo.completed
          ? colors.onPrimaryContainer
          : colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final headingStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final knownPriority = PriorityConfig.values.contains(todo.priority);
    final priorityLabel = knownPriority
        ? PriorityConfig.options(l10n)[todo.priority]!
        : '${l10n.priority}: ${todo.priority.isEmpty ? l10n.notSpecified : todo.priority}';

    double textWidth(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    Widget statusBadge(bool compact) => Tooltip(
      message: statusDescription,
      child: Semantics(
        label: statusDescription,
        excludeSemantics: true,
        child: compact
            ? Icon(
                todo.completed
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                size: 20,
                color: statusStyle?.color,
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: todo.completed
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(statusLabel, style: statusStyle, maxLines: 1),
              ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final dialogWidth = constraints.maxWidth * DialogConfig.widthFactor;
        final dateGap = dialogWidth < 520 ? 16.0 : 32.0;
        final dateColumnWidth = (dialogWidth - 48 - dateGap) / 2;
        final dateScale = (dateColumnWidth / 180).clamp(0.85, 1.0);
        final compactDates =
            dateColumnWidth < 180 ||
            MediaQuery.textScalerOf(context).scale(16) > 22;
        final dueDate = dateField(
          Icons.calendar_month_outlined,
          l10n.dueDate,
          DateTimeUtils.formatDate(todo.dueDate, localizations: materialL10n),
          compact: compactDates,
          scale: dateScale,
        );
        final createdDate = dateField(
          Icons.schedule_outlined,
          l10n.createdAt,
          createdAtText,
          compact: compactDates,
          scale: dateScale,
        );
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
                LayoutBuilder(
                  builder: (context, headerConstraints) {
                    final headingWidth =
                        38 + textWidth(l10n.details, headingStyle);
                    final priorityWidth = knownPriority
                        ? 41 + textWidth(priorityLabel, statusStyle)
                        : textWidth(priorityLabel, labelStyle);
                    final fullWidth =
                        headingWidth +
                        16 +
                        textWidth(statusLabel, statusStyle) +
                        24 +
                        8 +
                        priorityWidth;
                    final compact = fullWidth > headerConstraints.maxWidth;
                    final heading = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon.asset(AppIconAssets.task, size: 28),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(l10n.details, style: headingStyle),
                        ),
                      ],
                    );
                    final badges = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        statusBadge(compact),
                        const SizedBox(width: 8),
                        if (knownPriority)
                          TodoPriorityBadge(
                            priority: todo.priority,
                            compact: compact,
                          )
                        else if (compact)
                          Tooltip(
                            message: priorityLabel,
                            child: Icon(
                              Icons.flag_outlined,
                              size: 18,
                              semanticLabel: priorityLabel,
                            ),
                          )
                        else
                          Text(priorityLabel, style: labelStyle),
                      ],
                    );
                    // Give enlarged text its own row when even icons won't fit.
                    if (compact &&
                        headingWidth + 62 > headerConstraints.maxWidth) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [heading, badges],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: 16),
                        badges,
                      ],
                    );
                  },
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
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: dueDate),
                      VerticalDivider(width: dateGap),
                      Expanded(child: createdDate),
                    ],
                  ),
                ),
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
