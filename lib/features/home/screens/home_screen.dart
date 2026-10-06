import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../todo/providers/todo_provider.dart';
import '../../todo/services/todo_actions.dart';
import '../../todo/widgets/todo_item.dart';
import '../models/home_summary.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onOpenTasks});

  final VoidCallback onOpenTasks;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _actions = const TodoActions();
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final todos = ref.watch(todoProvider);
    final operations = ref.watch(todoOperationProvider);

    return todos.when(
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppError(
        onRetry: () => ref.read(todoProvider.notifier).refreshTodos(),
      ),
      data: (items) {
        final now = DateTime.now();
        final summary = HomeSummary.calculate(items, now);
        final heading = theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );
        return RefreshIndicator(
          onRefresh: ref.read(todoProvider.notifier).refreshTodos,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        size: 40,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.taskCount(summary.remaining), style: heading),
                      const SizedBox(height: 8),
                      Text(
                        l10n.homeDueSummary(summary.dueToday, summary.overdue),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Text(l10n.homeToday, style: heading)),
                  TextButton(
                    key: const ValueKey('home-view-all'),
                    onPressed: widget.onOpenTasks,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.homeViewAll),
                        const SizedBox(width: 6),
                        const Icon(CupertinoIcons.arrow_right, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              Card(
                color: colors.surface,
                child: summary.todayPreview.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.homeNoTasksToday,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      )
                    : Column(
                        children: [
                          for (
                            var i = 0;
                            i < summary.todayPreview.length;
                            i++
                          ) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                            TodoItem(
                              key: ValueKey(summary.todayPreview[i].id),
                              todo: summary.todayPreview[i],
                              currentDate: now,
                              itemNumber: i + 1,
                              isBusy: operations.busyIds.contains(
                                summary.todayPreview[i].id,
                              ),
                              onClick: () => _actions.view(
                                context,
                                ref,
                                summary.todayPreview[i],
                              ),
                              onToggle: () => _actions.toggle(
                                context,
                                ref,
                                summary.todayPreview[i],
                              ),
                              onEdit: () => _actions.edit(
                                context,
                                ref,
                                summary.todayPreview[i],
                              ),
                              onDelete: () => _actions.delete(
                                context,
                                ref,
                                summary.todayPreview[i],
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              Text(l10n.homeOverview, style: heading),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Wrap when large text would make three columns too narrow.
                  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                  final columns = constraints.maxWidth / scale < 270 ? 1 : 3;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _OverviewCard(
                        width: width,
                        icon: CupertinoIcons.calendar,
                        color: colors.onSurfaceVariant,
                        label: l10n.dueToday,
                        count: summary.dueToday,
                      ),
                      _OverviewCard(
                        width: width,
                        icon: CupertinoIcons.exclamationmark_circle,
                        color: colors.error,
                        label: l10n.filterOverdue,
                        count: summary.overdue,
                      ),
                      _OverviewCard(
                        width: width,
                        icon: CupertinoIcons.checkmark_circle,
                        color: colors.primary,
                        label: l10n.completed,
                        count: summary.completed,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Card(
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.homeCompletedProgress(
                                summary.completed,
                                summary.total,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(summary.progress * 100).round()}%',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: summary.progress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: colors.surfaceContainerHighest,
                        semanticsLabel: l10n.homeCompletedProgress(
                          summary.completed,
                          summary.total,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  final double width;
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
