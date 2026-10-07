import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_expandable_sheet.dart';
import '../../notifications/providers/daily_summary_controller.dart';
import '../providers/backup_controller.dart';
import '../services/backup_service.dart';
import 'backup_illustration.dart';

Future<void> showBackupFlow(
  BuildContext context,
  BackupController controller, {
  required bool restore,
  required VoidCallback onGoHome,
}) async {
  try {
    final complete = restore
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) =>
                _BackupFlowView(controller: controller, restore: true),
          )
        : await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  _BackupFlowView(controller: controller, restore: false),
            ),
          );
    if (complete != true || !context.mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _BackupComplete(controller: controller),
      ),
    );
    if (restore && context.mounted) onGoHome();
  } finally {
    controller.dispose();
  }
}

class _BackupFlowView extends StatefulWidget {
  const _BackupFlowView({required this.controller, required this.restore});
  final BackupController controller;
  final bool restore;
  @override
  State<_BackupFlowView> createState() => _BackupFlowViewState();
}

class _BackupFlowViewState extends State<_BackupFlowView> {
  BackupController get controller => widget.controller;
  bool _closing = false;
  @override
  void initState() {
    super.initState();
    controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          widget.restore ? controller.chooseBackup() : controller.startBackup(),
        );
      }
    });
  }

  void _changed() {
    if ({BackupStep.complete, BackupStep.cancelled}.contains(controller.step) &&
        !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(controller.step == BackupStep.complete);
        }
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    Widget body;
    String title;
    final actions = <Widget>[];
    void cancel() => Navigator.of(context).pop(false);
    Widget cancelButton() =>
        OutlinedButton(onPressed: cancel, child: Text(l.cancel));
    switch (controller.step) {
      case BackupStep.summary:
        title = l.backupData;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackupIllustration(),
            const SizedBox(height: 16),
            Text(
              l.backupDataSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              l.backupDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.backupIncluded,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    _Included(count: controller.taskCount, detailed: true),
                  ],
                ),
              ),
            ),
            _FileCard(name: controller.fileName),
            const SizedBox(height: 16),
            _Notice(
              text: l.backupPrivacyNotice,
              icon: Icons.lock_open_outlined,
            ),
          ],
        );
        actions.addAll([
          FilledButton.icon(
            onPressed: controller.createBackup,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(l.createBackup),
          ),
          TextButton(onPressed: cancel, child: Text(l.cancel)),
        ]);
      case BackupStep.preview:
        title = l.restoreBackup;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FileCard(name: controller.fileName),
            const SizedBox(height: 16),
            Text(l.backupCreatedDate),
            Text(
              DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                  .add_jm()
                  .format(controller.selected!.createdAt.toLocal()),
            ),
            const SizedBox(height: 24),
            Text(l.backupContains),
            _Included(count: controller.taskCount),
            const SizedBox(height: 16),
            _Notice(
              text: l.restoreReplaceWarning,
              icon: Icons.warning_amber_rounded,
              warning: true,
            ),
          ],
        );
        actions.addAll([
          cancelButton(),
          FilledButton(
            onPressed: controller.confirm,
            child: Text(l.backupContinue),
          ),
        ]);
      case BackupStep.confirm:
        title = l.replaceCurrentData;
        body = Column(
          children: [
            Icon(Icons.delete_outline, color: colors.error, size: 48),
            const SizedBox(height: 16),
            Text(l.replaceCurrentDataDescription),
            const SizedBox(height: 20),
            _Notice(
              text: l.restoreCannotUndo,
              icon: Icons.warning_amber_rounded,
              destructive: true,
            ),
          ],
        );
        final buttonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        );
        const buttonPadding = EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        );
        const buttonSize = Size.fromHeight(52);
        actions.add(
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    minimumSize: buttonSize,
                    padding: buttonPadding,
                    shape: buttonShape,
                  ),
                  onPressed: controller.restore,
                  child: Text(l.replaceAndRestore),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: buttonSize,
                    padding: buttonPadding,
                    shape: buttonShape,
                  ),
                  onPressed: cancel,
                  child: Text(l.cancel),
                ),
              ],
            ),
          ),
        );
      case BackupStep.error:
        final error = controller.error!;
        title = switch (error) {
          BackupFlowError.backup => l.backupFailedTitle,
          BackupFlowError.invalid => l.invalidBackupTitle,
          BackupFlowError.unsupported => l.unsupportedBackupTitle,
          BackupFlowError.restore => l.restoreFailedTitle,
        };
        body = Text(switch (error) {
          BackupFlowError.backup => l.backupFailedDescription,
          BackupFlowError.invalid => l.invalidBackupDescription,
          BackupFlowError.unsupported => l.unsupportedBackupDescription,
          BackupFlowError.restore => l.restoreFailedDescription,
        });
        actions.addAll([
          cancelButton(),
          FilledButton(
            onPressed: error == BackupFlowError.backup
                ? controller.createBackup
                : error == BackupFlowError.restore
                ? controller.preview
                : controller.chooseBackup,
            child: Text(
              error == BackupFlowError.backup ||
                      error == BackupFlowError.restore
                  ? l.retry
                  : l.chooseAnotherBackup,
            ),
          ),
        ]);
      default:
        title = switch (controller.step) {
          BackupStep.choosing => l.selectBackupFile,
          BackupStep.checking => l.checkingBackup,
          BackupStep.restoring => l.restoringBackup,
          BackupStep.saving => l.savingBackup,
          _ => l.creatingBackup,
        };
        body = Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                controller.step == BackupStep.restoring
                    ? l.restoreKeepOpen
                    : l.preparingBackup,
              ),
              if (controller.step == BackupStep.restoring &&
                  controller.restoreStage != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.restoreStage == RestoreStage.replacingTasks
                      ? l.restoreTasksStage
                      : l.restoreSettingsStage,
                ),
              ],
            ],
          ),
        );
    }
    if (!widget.restore) {
      return PopScope(
        canPop: !controller.busy,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 64 * MediaQuery.textScalerOf(context).scale(16) / 16,
            title: Text(
              controller.step == BackupStep.summary ? l.createBackup : title,
            ),
            leading: BackButton(onPressed: controller.busy ? null : cancel),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: body,
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: actions,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: !controller.busy,
      child: AppExpandableSheet(
        title: title,
        showCloseButton: false,
        body: body,
        actions: actions,
      ),
    );
  }
}

class _BackupComplete extends StatelessWidget {
  const _BackupComplete({required this.controller});
  final BackupController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, controller.notifications]),
    builder: (context, _) {
      final l = AppLocalizations.of(context)!;
      final colors = Theme.of(context).colorScheme;
      final restoring = controller.isRestore;
      final issue = controller.notifications.issue;
      return PopScope(
        canPop: !controller.busy && !controller.refreshFailed,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.check,
                          size: 48,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        restoring ? l.restoreComplete : l.backupCreated,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        restoring
                            ? l.restoreCompleteDescription
                            : l.backupCreatedDescription,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (!restoring) _FileCard(name: controller.fileName),
                      _Included(
                        count: controller.taskCount,
                        restored: restoring,
                      ),
                      if (restoring && controller.refreshFailed) ...[
                        _Notice(
                          text: l.restoreRefreshFailed,
                          icon: Icons.info_outline,
                        ),
                        TextButton(
                          onPressed: controller.busy
                              ? null
                              : controller.finishRestore,
                          child: Text(l.retry),
                        ),
                      ],
                      if (restoring && issue != null) ...[
                        _Notice(
                          text: issue == DailySummaryIssue.permissionDenied
                              ? l.dailySummaryPermissionDenied
                              : l.dailySummaryFailed,
                          icon: Icons.notifications_off_outlined,
                        ),
                        TextButton(
                          onPressed: controller.notifications.busy
                              ? null
                              : () async {
                                  if (issue ==
                                      DailySummaryIssue.permissionDenied) {
                                    await controller.notifications.setEnabled(
                                      true,
                                    );
                                  } else {
                                    await controller.notifications.refresh();
                                  }
                                },
                          child: Text(l.retry),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: controller.busy || controller.refreshFailed
                              ? null
                              : () => Navigator.of(context).pop(restoring),
                          child: Text(
                            restoring ? l.backupGoHome : l.backupDone,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Included extends StatelessWidget {
  const _Included({
    required this.count,
    this.restored = false,
    this.detailed = false,
  });
  final int count;
  final bool restored;
  final bool detailed;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final labels = [
      restored ? l.restoreTaskCount(count) : l.backupTaskCount(count),
      restored ? l.restoreAppSettingsComplete : l.backupAppSettings,
      restored ? l.restoreNotificationsComplete : l.backupNotificationSettings,
    ];
    final descriptions = [
      l.backupTasksDescription,
      l.backupAppSettingsDescription,
      l.backupNotificationSettingsDescription,
    ];
    final icons = [
      Icons.task_alt_outlined,
      Icons.settings_outlined,
      Icons.notifications_outlined,
    ];
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (detailed && i > 0) const Divider(height: 20, indent: 44),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  detailed ? icons[i] : Icons.check_circle_outline,
                  size: detailed ? 28 : 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(labels[i]),
                      if (detailed) ...[
                        const SizedBox(height: 4),
                        Text(
                          descriptions[i],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.icon,
    this.destructive = false,
    this.warning = false,
  });
  final String text;
  final IconData icon;
  final bool destructive;
  final bool warning;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final background = destructive
        ? colors.errorContainer
        : warning
        ? (isDark ? const Color(0xFF493809) : const Color(0xFFFFF3CD))
        : colors.secondaryContainer;
    final foreground = destructive
        ? colors.onErrorContainer
        : warning
        ? (isDark ? const Color(0xFFFFE29A) : const Color(0xFF664D03))
        : colors.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}
