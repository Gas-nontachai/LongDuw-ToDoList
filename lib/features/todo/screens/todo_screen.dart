import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/debouncer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design/app_icons.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/liquid_glass_bottom_navigation.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/todo.dart';
import '../models/todo_query.dart';
import '../widgets/todo_query_controls.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_form.dart';
import '../widgets/todo_detail.dart';
import '../widgets/tab_todo.dart';
import '../../../shared/design/app_icon_assets.dart';
import '../../../shared/widgets/app_icon.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    super.key,
  });

  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _searchDebouncer = Debouncer();
  final _searchController = TextEditingController();
  int _navigationIndex = 1;
  bool _isNavigationCompact = false;
  String _searchInput = '';
  String _searchQuery = '';
  TodoSort _sort = TodoSort.original;
  TodoFilter _filter = TodoFilter();
  Timer? _midnightTimer;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _tabController.dispose();
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

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

  void _onSearchChanged(String value) {
    setState(() => _searchInput = value);
    _searchDebouncer.run(() {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextDay.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _midnightTimer?.cancel();
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleMidnight();
    }
  }

  Future<void> _openFilter() async {
    FocusScope.of(context).unfocus();
    final value = await showTodoFilterSheet(context, _filter);
    if (value != null && mounted) setState(() => _filter = value);
  }

  Future<void> _openSort() async {
    FocusScope.of(context).unfocus();
    final value = await showTodoSortSheet(context, _sort);
    if (value != null && mounted) setState(() => _sort = value);
  }

  Future<void> _addTodo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final formData = await showTodoForm(context);
    if (formData == null || !context.mounted) return;
    await _runOperation(
      context,
      () => ref
          .read(todoProvider.notifier)
          .addTodo(
            formData.title,
            formData.details,
            priority: formData.priority,
            dueDate: formData.dueDate,
          ),
      l10n.todoAdded,
    );
  }

  Future<void> _getTodoById(
    BuildContext context,
    WidgetRef ref,
    Todo todo,
  ) async {
    final action = await showTodoDetail(context, todo: todo);
    if (!context.mounted) return;
    switch (action) {
      case TodoDetailAction.edit:
        await _editTodo(context, ref, todo);
      case TodoDetailAction.delete:
        await _deleteTodo(context, ref, todo);
      case null:
        break;
    }
  }

  Future<void> _editTodo(BuildContext context, WidgetRef ref, Todo todo) async {
    final l10n = AppLocalizations.of(context)!;
    final formData = await showTodoForm(context, todo: todo);
    if (formData == null || !context.mounted) return;
    await _runOperation(
      context,
      () => ref
          .read(todoProvider.notifier)
          .updateTodo(
            todo.copyWith(
              title: formData.title,
              details: formData.details,
              priority: formData.priority,
              dueDate: formData.dueDate,
              clearDueDate: formData.dueDate == null,
            ),
          ),
      l10n.todoUpdated,
    );
  }

  Future<void> _deleteTodo(
    BuildContext context,
    WidgetRef ref,
    Todo todo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTodoQuestion),
        content: Text(l10n.removeTodoConfirmation(todo.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _runOperation(
      context,
      () => ref.read(todoProvider.notifier).deleteTodo(todo),
      l10n.todoDeleted,
    );
  }

  Future<void> _runOperation(
    BuildContext context,
    Future<void> Function() operation,
    String successMessage,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // แสดง loading toast ค้างไว้ระหว่างรอ API ทำงาน
    final loadingToast = showAppToast(
      context,
      l10n.savingData,
      type: AppToastType.loading,
      alignment: Alignment.topRight,
      width: 340,
      animationIn: AppToastAnimation.slideAndFade,
      animationOut: AppToastAnimation.fade,
      duration: null,
    );

    try {
      await operation();
      // ปิด loading ก่อน แล้วค่อยแสดง success toast
      loadingToast.dismiss();
      if (context.mounted) _showMessage(context, successMessage);
    } catch (_) {
      // กรณี error ก็ต้องปิด loading ก่อนแสดง error toast
      loadingToast.dismiss();
      if (context.mounted) {
        _showMessage(
          context,
          l10n.somethingWentWrong,
          type: AppToastType.error,
        );
      }
    }
  }

  void _showMessage(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.success,
  }) {
    final isError = type == AppToastType.error;

    showAppToast(
      context,
      message,
      type: type,
      // ทดลองให้ toast อยู่มุมขวาบน และไม่กว้างเต็มหน้าจอ
      alignment: Alignment.topRight,
      width: 340,
      // success เด้งเข้าแบบ scale ส่วน error เลื่อนเข้าแบบ slide + fade
      animationIn: isError
          ? AppToastAnimation.slideAndFade
          : AppToastAnimation.scale,
      // ตอนออกใช้ fade เหมือนกันทั้งสองกรณี
      animationOut: AppToastAnimation.fade,
      inDuration: const Duration(milliseconds: 320),
      outDuration: const Duration(milliseconds: 220),
      inCurve: isError ? Curves.easeOut : Curves.easeOutBack,
      outCurve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todos = ref.watch(todoProvider);
    final operations = ref.watch(todoOperationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final filteredItems = queryTodos(
      todos.value ?? [],
      filter: _filter,
      sort: _sort,
      now: DateTime.now(),
      search: _searchQuery,
    );
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
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_circle,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.taskCount(taskCount),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => setState(() => _navigationIndex = 1),
                          icon: const Icon(CupertinoIcons.list_bullet),
                          label: Text(l10n.navTasks),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            todos.when(
              loading: () => const AppLoading(),
              error: (error, stackTrace) => AppError(
                onRetry: () => ref.read(todoProvider.notifier).refreshTodos(),
              ),
              data: (items) {
                return RefreshIndicator(
                  onRefresh: ref.read(todoProvider.notifier).refreshTodos,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(AppIcons.search),
                                  hintText: l10n.searchTodosHint,
                                  suffixIcon: _searchInput.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: l10n.clearSearchTooltip,
                                          icon: const Icon(AppIcons.close),
                                          onPressed: () {
                                            _searchDebouncer.dispose();
                                            _searchController.clear();
                                            setState(() {
                                              _searchInput = '';
                                              _searchQuery = '';
                                            });
                                          },
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TodoQueryButton(
                              key: const ValueKey('todo-filter-button'),
                              icon: Icons.filter_alt_outlined,
                              tooltip: l10n.filterTodos,
                              isActive: _filter.isActive,
                              onPressed: _openFilter,
                            ),
                            const SizedBox(width: 8),
                            TodoQueryButton(
                              key: const ValueKey('todo-sort-button'),
                              icon: AppIcons.sort,
                              tooltip:
                                  '${l10n.sortTodosTooltip}: ${todoSortLabel(_sort, l10n)}',
                              isActive: _sort != TodoSort.original,
                              onPressed: _openSort,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarTodo(
                          controller: _tabController,
                          todos: filteredItems,
                          hasQuery: _filter.isActive || _searchQuery.isNotEmpty,
                          busyIds: operations.busyIds,
                          onTodoTap: (todo) => _getTodoById(context, ref, todo),
                          onToggle: (todo) => _runOperation(
                            context,
                            () => ref
                                .read(todoProvider.notifier)
                                .toggleTodo(todo),
                            l10n.todoUpdated,
                          ),
                          onEdit: (todo) => _editTodo(context, ref, todo),
                          onDelete: (todo) => _deleteTodo(context, ref, todo),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                for (final entry in [
                  MapEntry(l10n.all, todos.value?.length ?? 0),
                  MapEntry(l10n.incomplete, taskCount),
                  MapEntry(
                    l10n.completed,
                    todos.value?.where((todo) => todo.completed).length ?? 0,
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
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(CupertinoIcons.moon),
                    title: Text(l10n.switchToDarkMode),
                    value: isDark,
                    onChanged: (dark) => widget.onThemeModeChanged(
                      dark ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(CupertinoIcons.globe),
                    title: Text(l10n.changeLanguage),
                    trailing: Text(isThai ? l10n.thai : l10n.english),
                    onTap: () =>
                        widget.onLocaleChanged(Locale(isThai ? 'en' : 'th')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: _navigationIndex != 1
          ? null
          : SizedBox(
              width: 64,
              height: 64,
              child: FloatingActionButton(
                onPressed: operations.isCreating
                    ? null
                    : () => _addTodo(context, ref),
                tooltip: l10n.addTodoTooltip,
                child: operations.isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(AppIcons.add, size: 34),
              ),
            ),
    );
  }
}
