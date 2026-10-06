import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_form.dart';
import '../widgets/todo_detail.dart';

/// Shared task interactions for Home and Tasks.
class TodoActions {
  const TodoActions();

  Future<void> toggle(BuildContext context, WidgetRef ref, Todo todo) =>
      runOperation(
        context,
        () => ref.read(todoProvider.notifier).toggleTodo(todo),
        AppLocalizations.of(context)!.todoUpdated,
      );

  Future<void> add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final formData = await showTodoForm(context);
    if (formData == null || !context.mounted) return;
    await runOperation(
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

  Future<void> view(BuildContext context, WidgetRef ref, Todo todo) async {
    final action = await showTodoDetail(context, todo: todo);
    if (!context.mounted) return;
    switch (action) {
      case TodoDetailAction.edit:
        await edit(context, ref, todo);
      case TodoDetailAction.delete:
        await delete(context, ref, todo);
      case null:
        break;
    }
  }

  Future<void> edit(BuildContext context, WidgetRef ref, Todo todo) async {
    final l10n = AppLocalizations.of(context)!;
    final formData = await showTodoForm(context, todo: todo);
    if (formData == null || !context.mounted) return;
    await runOperation(
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

  Future<void> delete(BuildContext context, WidgetRef ref, Todo todo) async {
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
    await runOperation(
      context,
      () => ref.read(todoProvider.notifier).deleteTodo(todo),
      l10n.todoDeleted,
    );
  }

  Future<void> runOperation(
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
}
