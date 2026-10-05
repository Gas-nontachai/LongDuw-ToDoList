import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/screens/home_screen.dart';
import '../features/todo/screens/todo_screen.dart';
import '../features/todo/providers/todo_provider.dart';
import '../features/stats/screens/stats_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/widgets/liquid_glass_bottom_navigation.dart';
import '../shared/design/app_icon_assets.dart';
import '../shared/widgets/app_icon.dart';

/// Shared app layout. Each destination owns its own screen content.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _navigationIndex = 1;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final taskCount = todos.value?.where((todo) => !todo.completed).length ?? 0;
    final destinations = [
      l10n.navHome,
      l10n.navTasks,
      l10n.navStats,
      l10n.navSettings,
    ];
    return Scaffold(
      extendBody: true,
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
            _isNavigationCompact = false;
          });
        },
      ),
      appBar: AppBar(
        toolbarHeight: 96,
        titleSpacing: 24,
        title: Row(
          children: [
            const AppIcon.asset(AppIconAssets.task, size: 28),
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
                  if (todos.hasValue && _navigationIndex != 3) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.taskCount(taskCount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? l10n.switchToLightMode : l10n.switchToDarkMode,
            icon: Icon(isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon),
            onPressed: () => widget.onThemeModeChanged(
              isDark ? ThemeMode.light : ThemeMode.dark,
            ),
          ),
          IconButton(
            tooltip: l10n.changeLanguage,
            icon: Text(
              isThai ? 'TH' : 'EN',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onPressed: () =>
                widget.onLocaleChanged(Locale(isThai ? 'en' : 'th')),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onBodyScroll,
        child: IndexedStack(
          index: _navigationIndex,
          children: [
            HomeScreen(
              taskCount: taskCount,
              onOpenTasks: () => setState(() => _navigationIndex = 1),
            ),
            const TodoScreen(),
            StatsScreen(todos: todos.value ?? const []),
            SettingsScreen(
              onLocaleChanged: widget.onLocaleChanged,
              onThemeModeChanged: widget.onThemeModeChanged,
            ),
          ],
        ),
      ),
    );
  }
}
