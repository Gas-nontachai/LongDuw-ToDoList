import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../todo/models/todo.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.todos});
  final List<Todo> todos;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final taskCount = todos.where((todo) => !todo.completed).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      children: [
        for (final entry in [
          MapEntry(l10n.all, todos.length),
          MapEntry(l10n.incomplete, taskCount),
          MapEntry(
            l10n.completed,
            todos.where((todo) => todo.completed).length,
          ),
        ])
          Card(
            child: ListTile(
              title: Text(entry.key),
              trailing: Text(
                '${entry.value}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
      ],
    );
  }
}
