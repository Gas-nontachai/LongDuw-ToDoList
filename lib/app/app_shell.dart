import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/screens/home_screen.dart';
import '../features/backup/providers/backup_controller.dart';
import '../features/backup/widgets/backup_flow.dart';
import '../features/backup/screens/data_backup_screen.dart';
import '../features/todo/screens/todo_screen.dart';
import '../features/todo/providers/todo_provider.dart';
import '../features/todo/services/todo_actions.dart';
import '../features/stats/screens/stats_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/notifications/providers/daily_summary_controller.dart';
import '../l10n/app_localizations.dart';
import '../shared/widgets/liquid_glass_bottom_navigation.dart';
import '../shared/design/app_icon_assets.dart';
import '../shared/design/app_icons.dart';
import '../shared/widgets/app_icon.dart';

/// Shared app layout. Each destination owns its own screen content.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    this.dailySummaryController,
    this.createBackupController,
    this.themeMode = ThemeMode.system,
    this.onReplayOnboarding,
  });
  final ThemeMode themeMode;
  final VoidCallback? onReplayOnboarding;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DailySummaryController? dailySummaryController;
  final BackupController Function(Future<void> Function())?
  createBackupController;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _todoActions = const TodoActions();
  int _navigationIndex = 0;
  int _restoreGeneration = 0;
  bool _backupOpen = false;
  bool _backupSettingsOpen = false;

  void _closeBackupSettings() {
    setState(() => _backupSettingsOpen = false);
  }

  Future<void> _openBackup(bool restore) async {
    if (_backupOpen || widget.createBackupController == null) return;
    _backupOpen = true;
    final controller = widget.createBackupController!(() async {
      await ref.read(todoProvider.notifier).refreshTodos();
      final todos = ref.read(todoProvider);
      if (todos.hasError) throw todos.error!;
      if (mounted) setState(() => _restoreGeneration++);
    });
    try {
      await showBackupFlow(
        context,
        controller,
        restore: restore,
        onGoHome: () {
          setState(() {
            _navigationIndex = 0;
            _backupSettingsOpen = false;
            _isNavigationCompact = false;
          });
        },
      );
    } finally {
      _backupOpen = false;
    }
  }

  bool _isNavigationCompact = false;
  void _collapseNavigation() {
    if (!_isNavigationCompact) {
      setState(() => _isNavigationCompact = true);
    }
  }

  bool _onBodyScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        ((notification is ScrollStartNotification &&
                notification.dragDetails != null) ||
            (notification is UserScrollNotification &&
                notification.direction != ScrollDirection.idle))) {
      _collapseNavigation();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todos = ref.watch(todoProvider);
    final operations = ref.watch(todoOperationProvider);
    final taskCount = todos.value?.where((todo) => !todo.completed).length ?? 0;
    final destinations = [
      l10n.navHome,
      l10n.navTasks,
      l10n.navStats,
      l10n.navSettings,
    ];
    return PopScope(
      canPop: !_backupSettingsOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _backupSettingsOpen) _closeBackupSettings();
      },
      child: Scaffold(
        extendBody: true,
        // Own the FAB alongside the navigation so Scaffold positions it above
        // the bar's actual height, including its animation and bottom safe area.
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _navigationIndex == 1
            ? SizedBox(
                width: 64,
                height: 64,
                child: FloatingActionButton(
                  onPressed: operations.isCreating
                      ? null
                      : () => _todoActions.add(context, ref),
                  tooltip: l10n.addTodoTooltip,
                  child: operations.isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.add, size: 34),
                ),
              )
            : null,
        bottomNavigationBar: LiquidGlassBottomNavigation(
          items: [
            LiquidGlassNavigationItem(
              icon: CupertinoIcons.house,
              label: l10n.navHome,
            ),
            LiquidGlassNavigationItem(
              icon: CupertinoIcons.list_bullet,
              label: l10n.navTasks,
            ),
            LiquidGlassNavigationItem(
              icon: CupertinoIcons.chart_bar,
              label: l10n.navStats,
            ),
            LiquidGlassNavigationItem(
              icon: CupertinoIcons.gear,
              label: l10n.navSettings,
            ),
          ],
          selectedIndex: _navigationIndex,
          isCompact: _isNavigationCompact,
          onTapOutside: _collapseNavigation,
          onSelected: (index) {
            FocusScope.of(context).unfocus();
            setState(() {
              _navigationIndex = index;
              _backupSettingsOpen = false;
              _isNavigationCompact = false;
            });
          },
        ),
        appBar: AppBar(
          toolbarHeight: _navigationIndex == 2
              ? (96 * MediaQuery.textScalerOf(context).scale(15) / 15).clamp(
                  96.0,
                  double.infinity,
                )
              : 96,
          leading: _backupSettingsOpen
              ? BackButton(onPressed: _closeBackupSettings)
              : null,
          titleSpacing: _backupSettingsOpen ? 0 : 24,
          title: _backupSettingsOpen
              ? Text(l10n.dataAndBackup)
              : Row(
                  children: [
                    const AppIcon.asset(AppIconAssets.logo, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _navigationIndex == 1
                                ? l10n.appTitle
                                : destinations[_navigationIndex],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_navigationIndex == 2 ||
                              (todos.hasValue && _navigationIndex != 3)) ...[
                            const SizedBox(height: 4),
                            Text(
                              _navigationIndex == 2
                                  ? l10n.statsSubtitle
                                  : l10n.taskCount(taskCount),
                              maxLines: _navigationIndex == 2 ? 1 : null,
                              overflow: _navigationIndex == 2
                                  ? TextOverflow.ellipsis
                                  : null,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
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
        body: NotificationListener<ScrollNotification>(
          onNotification: _onBodyScroll,
          child: IndexedStack(
            index: _navigationIndex,
            children: [
              HomeScreen(
                onOpenTasks: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _navigationIndex = 1;
                    _isNavigationCompact = false;
                  });
                },
              ),
              TodoScreen(key: ValueKey(_restoreGeneration)),
              const StatsScreen(),
              IndexedStack(
                index: _backupSettingsOpen ? 1 : 0,
                children: [
                  SettingsScreen(
                    themeMode: widget.themeMode,
                    onReplayOnboarding: widget.onReplayOnboarding,
                    onDataAndBackup: widget.createBackupController == null
                        ? null
                        : () => setState(() {
                            _backupSettingsOpen = true;
                            _isNavigationCompact = false;
                          }),
                    dailySummaryController: widget.dailySummaryController,
                    onLocaleChanged: widget.onLocaleChanged,
                    onThemeModeChanged: widget.onThemeModeChanged,
                  ),
                  DataBackupScreen(
                    onBackup: () => _openBackup(false),
                    onRestore: () => _openBackup(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
