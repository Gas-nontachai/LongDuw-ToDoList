import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.taskCount,
    required this.onOpenTasks,
  });
  final int taskCount;
  final VoidCallback onOpenTasks;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
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
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.taskCount(taskCount),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onOpenTasks,
                  icon: const Icon(CupertinoIcons.list_bullet),
                  label: Text(l10n.navTasks),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
