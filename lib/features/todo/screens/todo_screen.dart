import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/debouncer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design/app_icons.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/todo.dart';
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

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _searchDebouncer = Debouncer();
  final _searchController = TextEditingController();
  String _searchInput = '';
  String _searchQuery = '';

  @override
  void dispose() {
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

  List<Todo> _filterTodos(List<Todo> todos) {
    if (_searchQuery.isEmpty) return todos;

    return todos.where((todo) {
      return todo.title.toLowerCase().contains(_searchQuery) ||
          todo.details.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _addTodo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final formData = await showTodoForm(context);
    if (formData == null || !context.mounted) return;
    await _runOperation(
      context,
      () => ref
          .read(todoProvider.notifier)
          .addTodo(formData.title, formData.details),
      l10n.todoAdded,
    );
  }

  Future<void> _getTodoById(
    BuildContext context,
    WidgetRef ref,
    Todo todo,
  ) async {
    await showTodoDetail(context, todo: todo);
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
            todo.copyWith(title: formData.title, details: formData.details),
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppIcon.asset(AppIconAssets.task, size: 24),
            const SizedBox(width: 8),
            Text(l10n.appTitle),
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
      body: todos.when(
        loading: () => const AppLoading(),
        error: (error, stackTrace) => AppError(
          onRetry: () => ref.read(todoProvider.notifier).refreshTodos(),
        ),
        data: (items) {
          final filteredItems = _filterTodos(items);
          return RefreshIndicator(
            onRefresh: ref.read(todoProvider.notifier).refreshTodos,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: Icon(AppIcons.search),
                      hintText: l10n.searchTodosHint,
                      suffixIcon: _searchInput.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.clearSearchTooltip,
                              icon: const Icon(AppIcons.close),
                              onPressed: _searchController.clear,
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarTodo(
                    todos: filteredItems,
                    busyIds: operations.busyIds,
                    onTodoTap: (todo) => _getTodoById(context, ref, todo),
                    onToggle: (todo) => _runOperation(
                      context,
                      () => ref.read(todoProvider.notifier).toggleTodo(todo),
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
      floatingActionButton: FloatingActionButton(
        onPressed: operations.isCreating ? null : () => _addTodo(context, ref),
        tooltip: l10n.addTodoTooltip,
        child: operations.isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(AppIcons.add),
      ),
    );
  }
}
