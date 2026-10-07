import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/config/dev_config.dart';
import '../../notifications/providers/daily_summary_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    this.dailySummaryController,
    this.onDataAndBackup,
  });
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DailySummaryController? dailySummaryController;
  final VoidCallback? onDataAndBackup;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
      children: [
        const _AppVersionSettings(),
        if (dailySummaryController != null)
          _DailySummarySettings(controller: dailySummaryController!),
        Card(
          child: SwitchListTile(
            secondary: const Icon(CupertinoIcons.moon),
            title: Text(l10n.switchToDarkMode),
            value: isDark,
            onChanged: (dark) =>
                onThemeModeChanged(dark ? ThemeMode.dark : ThemeMode.light),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(CupertinoIcons.globe),
            title: Text(l10n.changeLanguage),
            trailing: Text(isThai ? l10n.thai : l10n.english),
            onTap: () => onLocaleChanged(Locale(isThai ? 'en' : 'th')),
          ),
        ),
        if (onDataAndBackup != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settingsData,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              minTileHeight: 48,
              leading: Icon(
                CupertinoIcons.tray_full,
                size: 22,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: Text(l10n.dataAndBackup),
              trailing: Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: onDataAndBackup,
            ),
          ),
        ],
      ],
    );
  }
}

class _AppVersionSettings extends StatefulWidget {
  const _AppVersionSettings();

  @override
  State<_AppVersionSettings> createState() => _AppVersionSettingsState();
}

class _AppVersionSettingsState extends State<_AppVersionSettings> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: _packageInfo,
    builder: (context, snapshot) {
      final info = snapshot.data;
      final version = info == null
          ? '—'
          : info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(AppLocalizations.of(context)!.settingsAppVersion),
              Text(version),
            ],
          ),
        ),
      );
    },
  );
}

class _DailySummarySettings extends StatelessWidget {
  const _DailySummarySettings({required this.controller});

  final DailySummaryController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context)!;
      final time = TimeOfDay(
        hour: controller.reminderMinutes ~/ 60,
        minute: controller.reminderMinutes % 60,
      );
      return Card(
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(CupertinoIcons.bell),
              title: Text(l10n.dailySummary),
              subtitle: !controller.supported
                  ? Text(l10n.dailySummaryUnsupported)
                  : null,
              value: controller.enabled,
              onChanged: controller.supported && !controller.busy
                  ? controller.setEnabled
                  : null,
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.clock),
              title: Text(l10n.reminderTime),
              trailing: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              ),
              enabled: controller.supported && !controller.busy,
              onTap: controller.supported && !controller.busy
                  ? () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: time,
                        builder: (context, child) => MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                      );
                      if (selected != null) {
                        await controller.setReminderMinutes(
                          selected.hour * 60 + selected.minute,
                        );
                      }
                    }
                  : null,
            ),
            if (controller.issue != null)
              ListTile(
                title: Text(
                  controller.issue == DailySummaryIssue.permissionDenied
                      ? l10n.dailySummaryPermissionDenied
                      : l10n.dailySummaryFailed,
                ),
                trailing: TextButton(
                  onPressed: controller.busy
                      ? null
                      : () =>
                            controller.issue ==
                                DailySummaryIssue.permissionDenied
                            ? controller.setEnabled(true)
                            : controller.refresh(),
                  child: Text(l10n.retry),
                ),
              ),
            if (devToolsEnabled)
              ListTile(
                leading: const Icon(CupertinoIcons.paperplane),
                title: Text(l10n.testNotification),
                subtitle: Text(l10n.testNotificationDescription),
                enabled: controller.supported && !controller.busy,
                onTap: controller.supported && !controller.busy
                    ? () async {
                        final result = await controller.testNotification();
                        if (!context.mounted) return;
                        final message = switch (result) {
                          TestNotificationResult.shown =>
                            l10n.testNotificationSent,
                          TestNotificationResult.permissionDenied =>
                            l10n.dailySummaryPermissionDenied,
                          TestNotificationResult.failed =>
                            l10n.testNotificationFailed,
                          TestNotificationResult.unavailable =>
                            l10n.dailySummaryUnsupported,
                        };
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(message)));
                      }
                    : null,
              ),
          ],
        ),
      );
    },
  );
}
