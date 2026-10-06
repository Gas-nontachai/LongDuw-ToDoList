import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../todo/providers/todo_provider.dart';
import '../models/stats_summary.dart';

const _blue = Color(0xFF4D73FF);
const _teal = Color(0xFF009688);
const _orange = Color(0xFFFF8126);
const _red = Color(0xFFFF5964);
const _yellow = Color(0xFFF8B938);
const _purple = Color(0xFF8C9DF4);
const _gray = Color(0xFF8794AA);

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with WidgetsBindingObserver {
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
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(tomorrow.difference(now), () {
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
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todos = ref.watch(todoProvider);
    return todos.when(
      loading: () => const AppLoading(),
      error: (error, stack) => AppError(
        onRetry: () => ref.read(todoProvider.notifier).refreshTodos(),
      ),
      data: (items) {
        final summary = StatsSummary.calculate(items, DateTime.now());
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                final columns = constraints.maxWidth / scale < 300 ? 1 : 3;
                final width =
                    (constraints.maxWidth - (columns - 1) * 10) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      key: const ValueKey('stats-total'),
                      width: width,
                      label: l10n.statsTotalTasks,
                      count: summary.total,
                      icon: CupertinoIcons.list_bullet,
                      color: _blue,
                    ),
                    _MetricCard(
                      key: const ValueKey('stats-completed'),
                      width: width,
                      label: l10n.completed,
                      count: summary.completed,
                      icon: CupertinoIcons.check_mark,
                      color: _teal,
                    ),
                    _MetricCard(
                      key: const ValueKey('stats-remaining'),
                      width: width,
                      label: l10n.statsRemaining,
                      count: summary.remaining,
                      icon: CupertinoIcons.arrow_2_circlepath,
                      color: _orange,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _StatsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PanelHeading(l10n.statsCompletionRate),
                            const SizedBox(height: 6),
                            Text(
                              l10n.homeCompletedProgress(
                                summary.completed,
                                summary.total,
                              ),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(summary.progress * 100).round()}%',
                        key: const ValueKey('stats-completion-percent'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProgressBar(
                    value: summary.progress,
                    color: _teal,
                    height: 16,
                    label: l10n.statsCompletionRate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StatsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelHeading(l10n.statsByPriority),
                  const SizedBox(height: 12),
                  _DistributionRow(
                    label: l10n.priorityHigh,
                    count: summary.high,
                    total: summary.total,
                    color: _red,
                  ),
                  _DistributionRow(
                    label: l10n.priorityMedium,
                    count: summary.medium,
                    total: summary.total,
                    color: _yellow,
                  ),
                  _DistributionRow(
                    label: l10n.priorityLow,
                    count: summary.low,
                    total: summary.total,
                    color: _purple,
                  ),
                  if (summary.unspecified > 0)
                    _DistributionRow(
                      label: l10n.notSpecified,
                      count: summary.unspecified,
                      total: summary.total,
                      color: _gray,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StatsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelHeading(l10n.statsByDueDate),
                  const SizedBox(height: 4),
                  Text(
                    l10n.statsIncompleteOnly,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DistributionRow(
                    label: l10n.filterOverdue,
                    count: summary.overdue,
                    total: summary.remaining,
                    color: _red,
                    icon: CupertinoIcons.exclamationmark_circle_fill,
                  ),
                  _DistributionRow(
                    label: l10n.dueToday,
                    count: summary.dueToday,
                    total: summary.remaining,
                    color: _orange,
                    icon: CupertinoIcons.clock,
                  ),
                  _DistributionRow(
                    label: l10n.statsDueSoon,
                    count: summary.dueSoon,
                    total: summary.remaining,
                    color: _yellow,
                    icon: CupertinoIcons.calendar,
                  ),
                  _DistributionRow(
                    label: l10n.noDueDate,
                    count: summary.noDueDate,
                    total: summary.remaining,
                    color: _gray,
                    icon: CupertinoIcons.nosign,
                  ),
                  if (summary.later > 0)
                    _DistributionRow(
                      label: l10n.statsLater,
                      count: summary.later,
                      total: summary.remaining,
                      color: _blue,
                      icon: CupertinoIcons.calendar,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.width,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: dark ? .12 : .035),
            theme.colorScheme.surface,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: dark ? .2 : .08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: dark ? .18 : .08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                '$count',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.color,
    required this.label,
    this.height = 10,
  });
  final double value;
  final Color color;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
    value: value,
    color: color,
    backgroundColor: Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFECF1F5)
        : Theme.of(context).colorScheme.surfaceContainerHighest,
    minHeight: height,
    borderRadius: BorderRadius.circular(height),
    semanticsLabel: label,
    semanticsValue: '${(value * 100).round()}%',
  );
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    this.icon,
  });
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : count / total;
    final marker = icon == null
        ? Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
        : Icon(icon, color: color, size: 22);
    final title = Text(
      label,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    final bar = _ProgressBar(value: progress, color: color, label: label);
    return Semantics(
      label: '$label: $count',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final compact = constraints.maxWidth / scale < 280;
            final labelRow = Row(
              children: [
                SizedBox(width: 24, child: Center(child: marker)),
                const SizedBox(width: 8),
                Expanded(child: title),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  Expanded(child: bar),
                ],
                const SizedBox(width: 12),
                Text('$count'),
              ],
            );
            return compact
                ? Column(
                    children: [
                      labelRow,
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: bar,
                      ),
                    ],
                  )
                : labelRow;
          },
        ),
      ),
    );
  }
}
