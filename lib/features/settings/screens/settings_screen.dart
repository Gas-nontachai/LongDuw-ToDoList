import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../shared/widgets/app_theme_selector.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/config/dev_config.dart';
import '../../notifications/providers/daily_summary_controller.dart';
import 'software_licenses_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    this.dailySummaryController,
    this.onDataAndBackup,
    this.themeMode = ThemeMode.system,
    this.onReplayOnboarding,
  });
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DailySummaryController? dailySummaryController;
  final VoidCallback? onDataAndBackup;
  final ThemeMode themeMode;
  final VoidCallback? onReplayOnboarding;
  Future<T?> _showPicker<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
  }) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              builder(sheetContext),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _chooseTheme(BuildContext context) async {
    final selected = await _showPicker<ThemeMode>(
      context,
      title: AppLocalizations.of(context)!.appTheme,
      builder: (sheetContext) => AppThemeSelector(
        value: themeMode,
        onChanged: (mode) => Navigator.of(sheetContext).pop(mode),
      ),
    );
    if (selected != null && context.mounted) onThemeModeChanged(selected);
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final selected = await _showPicker<Locale>(
      context,
      title: l10n.onboardingLanguage,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final code in ['th', 'en'])
            Card(
              child: ListTile(
                key: ValueKey('settings-language-$code'),
                leading: const Icon(CupertinoIcons.globe),
                title: Text(code == 'th' ? l10n.thai : l10n.english),
                selected: language == code,
                selectedTileColor: Theme.of(sheetContext)
                    .colorScheme
                    .primaryContainer,
                trailing: Icon(
                  language == code ? Icons.check_circle : Icons.circle_outlined,
                ),
                onTap: () => Navigator.of(sheetContext).pop(Locale(code)),
              ),
            ),
        ],
      ),
    );
    if (selected != null && context.mounted) onLocaleChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
      children: [
        const _AppVersionSettings(),
        if (dailySummaryController != null)
          _DailySummarySettings(controller: dailySummaryController!),
        Card(
          child: ListTile(
            key: const ValueKey('settings-theme'),
            leading: Icon(themeModeIcon(themeMode)),
            title: Text(l10n.appTheme),
            subtitle: Text(themeModeLabel(l10n, themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseTheme(context),
          ),
        ),
        Card(
          child: ListTile(
            key: const ValueKey('settings-language'),
            leading: const Icon(CupertinoIcons.globe),
            title: Text(l10n.onboardingLanguage),
            subtitle: Text(isThai ? l10n.thai : l10n.english),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseLanguage(context),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.settingsAbout,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Card(
          child: Column(
            children: [
              if (onReplayOnboarding != null) ...[
                _AboutSettingsTile(
                  icon: Icons.help_outline,
                  title: l10n.onboardingReplay,
                  onTap: onReplayOnboarding!,
                ),
                const Divider(height: 1, indent: 54, endIndent: 16),
              ],
              _AboutSettingsTile(
                key: const ValueKey('settings-licenses'),
                icon: Icons.description_outlined,
                title: l10n.softwareLicenses,
                secondary: true,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const SoftwareLicensesScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutSettingsTile extends StatelessWidget {
  const _AboutSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.secondary = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minTileHeight: 56,
      minLeadingWidth: 22,
      horizontalTitleGap: 16,
      leading: Icon(icon, size: 22, color: muted),
      title: Text(
        title,
        style: secondary
            ? theme.textTheme.bodyMedium?.copyWith(color: muted)
            : theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: muted),
      onTap: onTap,
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
      const showBuildNumber = kDebugMode || bool.fromEnvironment('DEV_TOOLS');
      final version = info == null
          ? '—'
          : !showBuildNumber || info.buildNumber.isEmpty
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
