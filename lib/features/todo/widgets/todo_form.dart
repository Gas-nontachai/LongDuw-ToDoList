import 'package:flutter/material.dart';

import '../../../core/config/priority_config.dart';
import '../../../shared/widgets/app_expandable_sheet.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../models/todo.dart';
import 'todo_form_fields.dart';

Future<TodoFormData?> showTodoForm(BuildContext context, {Todo? todo}) {
  return showModalBottomSheet<TodoFormData>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (_) => TodoFormSheet(todo: todo),
  );
}

class TodoFormData {
  const TodoFormData({
    required this.title,
    required this.details,
    required this.priority,
    this.dueDate,
  });

  final String title;
  final String details;
  final String priority;
  final DateTime? dueDate;
}

class TodoFormSheet extends StatefulWidget {
  const TodoFormSheet({this.todo, super.key});

  final Todo? todo;

  @override
  State<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends State<TodoFormSheet> {
  late final TextEditingController _controller;
  late final TextEditingController _detailsController;
  late final TextEditingController _dueDateController;
  late String _priority;
  DateTime? _dueDate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.todo?.title ?? '');
    _detailsController = TextEditingController(
      text: widget.todo?.details ?? '',
    );
    _dueDateController = TextEditingController();
    _dueDate = widget.todo?.dueDate;
    _priority = PriorityConfig.values.contains(widget.todo?.priority)
        ? widget.todo!.priority
        : PriorityConfig.medium;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDueDateText();
  }

  void _updateDueDateText() {
    _dueDateController.text = DateTimeUtils.formatDate(
      _dueDate,
      localizations: MaterialLocalizations.of(context),
    );
  }

  Future<void> _pickDueDate() async {
    final initialDate = _dueDate ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year < 1900 ? initialDate.year : 1900),
      lastDate: DateTime(
        initialDate.year > 2200 ? initialDate.year : 2200,
        12,
        31,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dueDate = selected;
      _updateDueDateText();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _detailsController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(
        TodoFormData(
          title: _controller.text.trim(),
          details: _detailsController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppExpandableSheet(
      title: widget.todo == null ? l10n.addTodo : l10n.editTodo,
      body: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: TodoFormFields(
            titleController: _controller,
            detailsController: _detailsController,
            dueDateController: _dueDateController,
            priority: _priority,
            dueDate: _dueDate,
            onPriorityChanged: (value) => setState(() => _priority = value),
            onPickDueDate: _pickDueDate,
            onClearDueDate: () => setState(() {
              _dueDate = null;
              _updateDueDateText();
            }),
            onSubmit: _save,
          ),
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
