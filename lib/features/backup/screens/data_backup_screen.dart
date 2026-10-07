import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../widgets/backup_illustration.dart';

/// Content hosted in the settings tab so the app navigation stays available.
class DataBackupScreen extends StatelessWidget {
  const DataBackupScreen({
    super.key,
    required this.onBackup,
    required this.onRestore,
  });

  final VoidCallback onBackup;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 128),
      children: [
        const BackupIllustration(overview: true),
        const SizedBox(height: 16),
        Text(
          l.backupOverviewTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.backupOverviewDescription,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        _ActionCard(
          icon: Icons.file_upload_outlined,
          title: l.createBackup,
          subtitle: l.backupDataSubtitle,
          onTap: onBackup,
        ),
        _ActionCard(
          icon: Icons.file_download_outlined,
          title: l.restoreBackup,
          subtitle: l.restoreBackupSubtitle,
          onTap: onRestore,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.restoreReplaceWarning,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      leading: Icon(
        icon,
        size: 30,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
