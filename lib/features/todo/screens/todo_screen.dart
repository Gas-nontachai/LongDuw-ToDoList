import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/debouncer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design/app_icons.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../models/todo_query.dart';
import '../widgets/todo_query_controls.dart';
import '../providers/todo_provider.dart';
import '../services/todo_actions.dart';
import '../widgets/tab_todo.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _actions = const TodoActions();
  final _searchDebouncer = Debouncer();
  final _searchController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todos = ref.watch(todoProvider);
    final operations = ref.watch(todoOperationProvider);
    final filteredItems = queryTodos(
      todos.value ?? [],
      filter: _filter,
      sort: _sort,
      now: DateTime.now(),
      search: _searchQuery,
    );
    return Scaffold(
      // AppShell draws the navigation over the body; keep its background visible.
      backgroundColor: Colors.transparent,
      body: todos.when(
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
                    onTodoTap: (todo) => _actions.view(context, ref, todo),
                    onToggle: (todo) => _actions.toggle(context, ref, todo),
                    onEdit: (todo) => _actions.edit(context, ref, todo),
                    onDelete: (todo) => _actions.delete(context, ref, todo),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
