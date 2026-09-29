import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/todo.dart';

Future<TodoFormData?> showTodoForm(BuildContext context, {Todo? todo}) {
  return showDialog<TodoFormData>(
    context: context,
    builder: (_) => TodoFormDialog(todo: todo),
  );
}

class TodoFormData {
  const TodoFormData({required this.title, required this.details});

  final String title;
  final String details;
}

class TodoFormDialog extends StatefulWidget {
  const TodoFormDialog({this.todo, super.key});

  final Todo? todo;

  @override
  State<TodoFormDialog> createState() => _TodoFormDialogState();
}

class _TodoFormDialogState extends State<TodoFormDialog> {
  late final TextEditingController _controller;
  late final TextEditingController _detailsController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.todo?.title ?? '');
    _detailsController = TextEditingController(
      text: widget.todo?.details ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(
        TodoFormData(
          title: _controller.text.trim(),
          details: _detailsController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.todo == null ? l10n.addTodo : l10n.editTodo),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.title),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.enterTitle
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.details),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.enterDetails
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.todo == null ? l10n.addTodo : l10n.save),
        ),
      ],
    );
  }
}
