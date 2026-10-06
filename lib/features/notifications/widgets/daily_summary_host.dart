import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_preferences.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../backup/providers/backup_controller.dart';
import '../../backup/services/backup_service.dart';
import '../../backup/services/backup_file_gateway.dart';
import '../../../app/app_shell.dart';
import '../../todo/providers/todo_provider.dart';
import '../providers/daily_summary_controller.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(),
);

class DailySummaryHost extends ConsumerStatefulWidget {
  const DailySummaryHost({
    super.key,
    required this.preferences,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });

  final AppPreferences preferences;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  ConsumerState<DailySummaryHost> createState() => _DailySummaryHostState();
}

class _DailySummaryHostState extends ConsumerState<DailySummaryHost>
    with WidgetsBindingObserver {
  late final DailySummaryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DailySummaryController(
      preferences: widget.preferences,
      notifications: ref.read(notificationServiceProvider),
      loadTodos: ref.read(todoServiceProvider).getTodos,
    );
    WidgetsBinding.instance.addObserver(this);
    unawaited(_controller.refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_controller.resolvedLocale != locale) {
      _controller.resolvedLocale = locale;
      unawaited(_controller.refresh());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_controller.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(todoProvider, (previous, next) {
      if (next.hasValue && !identical(previous?.value, next.value)) {
        unawaited(_controller.refresh());
      }
    });
    return AppShell(
      onLocaleChanged: widget.onLocaleChanged,
      onThemeModeChanged: widget.onThemeModeChanged,
      dailySummaryController: _controller,
      createBackupController: ref.watch(backupFileGatewayProvider).supported
          ? (reloadApp) => BackupController(
              service: BackupService(preferences: widget.preferences),
              files: ref.read(backupFileGatewayProvider),
              appVersion: () async =>
                  (await PackageInfo.fromPlatform()).version,
              notifications: _controller,
              reloadApp: () async {
                _controller.resolvedLocale =
                    widget.preferences.locale ??
                    basicLocaleListResolution(
                      WidgetsBinding.instance.platformDispatcher.locales,
                      AppLocalizations.supportedLocales,
                    );
                await reloadApp();
              },
            )
          : null,
    );
  }
}
