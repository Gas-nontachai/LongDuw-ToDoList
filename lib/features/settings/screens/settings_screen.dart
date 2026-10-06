import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/config/dev_config.dart';
import '../../notifications/providers/daily_summary_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    this.dailySummaryController,
  });
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DailySummaryController? dailySummaryController;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      children: [
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
      ],
    );
  }
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
              trailing: Text(time.format(context)),
              enabled: controller.supported && !controller.busy,
              onTap: controller.supported && !controller.busy
                  ? () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: time,
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
                                    DailySummaryIssue.permissionDenied &&
                                !controller.enabled
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
