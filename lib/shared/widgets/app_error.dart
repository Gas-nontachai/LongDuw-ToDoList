import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AppError extends StatelessWidget {
  const AppError({required this.onRetry, super.key});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.couldNotLoadTodos),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(CupertinoIcons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    ),
  );
}
