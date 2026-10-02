import 'package:flutter/material.dart';

import '../../../core/config/priority_config.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../models/todo_query.dart';

String todoSortLabel(TodoSort sort, AppLocalizations l10n) => switch (sort) {
  TodoSort.original => l10n.sortOriginal,
  TodoSort.titleAscending => l10n.sortTitleAscending,
  TodoSort.titleDescending => l10n.sortTitleDescending,
  TodoSort.dueAscending => l10n.sortDueAscending,
  TodoSort.dueDescending => l10n.sortDueDescending,
  TodoSort.priorityDescending => l10n.sortPriorityDescending,
  TodoSort.priorityAscending => l10n.sortPriorityAscending,
  TodoSort.createdDescending => l10n.sortCreatedDescending,
  TodoSort.createdAscending => l10n.sortCreatedAscending,
};

String todoDueFilterLabel(TodoDueFilter value, AppLocalizations l10n) =>
    switch (value) {
      TodoDueFilter.overdue => l10n.filterOverdue,
      TodoDueFilter.today => l10n.filterToday,
      TodoDueFilter.withinSevenDays => l10n.filterSevenDays,
      TodoDueFilter.withinThreeDays => l10n.filterThreeDays,
    };

IconData _sortIcon(TodoSort sort) => switch (sort) {
  TodoSort.original => Icons.format_list_bulleted,
  TodoSort.titleAscending || TodoSort.titleDescending => Icons.sort_by_alpha,
  TodoSort.dueAscending ||
  TodoSort.dueDescending => Icons.calendar_today_outlined,
  TodoSort.priorityDescending ||
  TodoSort.priorityAscending => Icons.flag_outlined,
  TodoSort.createdDescending || TodoSort.createdAscending => Icons.schedule,
};

Future<TodoFilter?> showTodoFilterSheet(
  BuildContext context,
  TodoFilter value,
) => showModalBottomSheet<TodoFilter>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _TodoFilterSheet(value: value),
);

Future<TodoSort?> showTodoSortSheet(BuildContext context, TodoSort value) =>
    showModalBottomSheet<TodoSort>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _TodoSortSheet(value: value),
    );

class TodoQueryButton extends StatelessWidget {
  const TodoQueryButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
    super.key,
  });
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: isActive ? colors.primary : colors.onSurfaceVariant,
        backgroundColor: colors.surfaceContainerLow,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      icon: Badge(
        isLabelVisible: isActive,
        backgroundColor: colors.primary,
        child: Icon(icon),
      ),
    );
  }
}

Color _priorityColor(String priority) => switch (priority) {
  PriorityConfig.high => Colors.red,
  PriorityConfig.medium => Colors.orange,
  _ => Colors.blue,
};

String _rangeLabel(BuildContext context, TodoFilter value) {
  final localizations = MaterialLocalizations.of(context);
  return '${DateTimeUtils.formatDate(value.startDate, localizations: localizations)} → '
      '${DateTimeUtils.formatDate(value.endDate, localizations: localizations)}';
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.onReset,
    required this.body,
    required this.applyLabel,
    required this.onApply,
  });
  final String title;
  final VoidCallback onReset;
  final Widget body;
  final String applyLabel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton(onPressed: onReset, child: Text(l10n.resetQuery)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: body,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApply,
                      child: Text(applyLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoFilterSheet extends StatefulWidget {
  const _TodoFilterSheet({required this.value});
  final TodoFilter value;
  @override
  State<_TodoFilterSheet> createState() => _TodoFilterSheetState();
}

class _TodoFilterSheetState extends State<_TodoFilterSheet> {
  late TodoFilter draft = widget.value;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial = draft.startDate == null
        ? null
        : DateTimeRange(
            start: DateTime(
              draft.startDate!.year,
              draft.startDate!.month,
              draft.startDate!.day,
            ),
            end: DateTime(
              draft.endDate!.year,
              draft.endDate!.month,
              draft.endDate!.day,
            ),
          );
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      currentDate: now,
      initialDateRange: initial,
      // Keep the range picker's fixed-height input form usable with our theme.
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null && mounted) {
      setState(
        () =>
            draft = draft.copyWith(startDate: range.start, endDate: range.end),
      );
    }
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final priorities = PriorityConfig.options(l10n);
    return _SheetFrame(
      title: l10n.filterTodos,
      onReset: () => setState(() => draft = TodoFilter()),
      applyLabel: l10n.applyFilters(draft.count),
      onApply: () => Navigator.pop(context, draft),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(l10n.priority),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final priority in PriorityConfig.values.reversed)
                FilterChip(
                  label: Text(priorities[priority]!),
                  avatar: Icon(Icons.flag, color: _priorityColor(priority)),
                  selected: draft.priorities.contains(priority),
                  onSelected: (selected) => setState(() {
                    final values = {...draft.priorities};
                    selected ? values.add(priority) : values.remove(priority);
                    draft = draft.copyWith(priorities: values);
                  }),
                ),
            ],
          ),
          _heading(l10n.dueDate),
          for (final due in TodoDueFilter.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              secondary: Icon(
                due == TodoDueFilter.overdue
                    ? Icons.schedule
                    : Icons.calendar_today_outlined,
              ),
              title: Text(todoDueFilterLabel(due, l10n)),
              value: draft.dueFilters.contains(due),
              onChanged: !draft.allowsDueDate
                  ? null
                  : (selected) => setState(() {
                      final values = {...draft.dueFilters};
                      selected == true ? values.add(due) : values.remove(due);
                      draft = draft.copyWith(dueFilters: values);
                    }),
            ),
          const Divider(),
          _heading(l10n.duePresenceTitle),
          RadioGroup<TodoDuePresence>(
            groupValue: draft.duePresence,
            onChanged: (value) {
              if (value != null) {
                setState(() => draft = draft.copyWith(duePresence: value));
              }
            },
            child: Column(
              children: [
                for (final presence in TodoDuePresence.values)
                  RadioListTile<TodoDuePresence>(
                    contentPadding: EdgeInsets.zero,
                    value: presence,
                    title: Text(switch (presence) {
                      TodoDuePresence.all => l10n.all,
                      TodoDuePresence.hasDate => l10n.hasDueDate,
                      TodoDuePresence.noDate => l10n.noDueDate,
                    }),
                  ),
              ],
            ),
          ),
          const Divider(),
          _heading(l10n.dateRangeTitle),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TodoDateField>(
              segments: [
                ButtonSegment(
                  value: TodoDateField.dueDate,
                  enabled: draft.allowsDueDate,
                  label: Text(l10n.dueDate),
                ),
                ButtonSegment(
                  value: TodoDateField.createdAt,
                  label: Text(l10n.createdAt),
                ),
              ],
              selected: {draft.dateField},
              onSelectionChanged: (values) => setState(
                () => draft = draft.copyWith(dateField: values.single),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.date_range_outlined),
              onPressed:
                  !draft.allowsDueDate &&
                      draft.dateField == TodoDateField.dueDate
                  ? null
                  : _pickRange,
              label: Text(
                draft.startDate == null
                    ? l10n.selectDateRange
                    : _rangeLabel(context, draft),
              ),
            ),
          ),
          if (draft.startDate != null)
            TextButton(
              onPressed: () =>
                  setState(() => draft = draft.copyWith(clearRange: true)),
              child: Text(l10n.clearDateRange),
            ),
        ],
      ),
    );
  }
}

class _TodoSortSheet extends StatefulWidget {
  const _TodoSortSheet({required this.value});
  final TodoSort value;
  @override
  State<_TodoSortSheet> createState() => _TodoSortSheetState();
}

class _TodoSortSheetState extends State<_TodoSortSheet> {
  late TodoSort draft = widget.value;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SheetFrame(
      title: l10n.sortBy,
      onReset: () => setState(() => draft = TodoSort.original),
      applyLabel: l10n.applySort,
      onApply: () => Navigator.pop(context, draft),
      body: Column(
        children: [
          for (final sort in TodoSort.values) ...[
            if ([
              TodoSort.dueAscending,
              TodoSort.priorityDescending,
              TodoSort.createdDescending,
            ].contains(sort))
              const Divider(),
            Semantics(
              checked: sort == draft,
              inMutuallyExclusiveGroup: true,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  sort == draft
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: sort == draft
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Row(
                  children: [
                    Icon(_sortIcon(sort)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(todoSortLabel(sort, l10n))),
                  ],
                ),
                onTap: () => setState(() => draft = sort),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
