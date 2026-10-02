import 'package:flutter/material.dart';

import '../../../core/config/priority_config.dart';
import '../../../shared/widgets/app_expandable_sheet.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/todo.dart';
import 'todo_priority_badge.dart';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _controller,
                autofocus: false,
                textInputAction: TextInputAction.done,
                label: l10n.title,
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.priority),
                items: [
                  for (final priority in PriorityConfig.values)
                    DropdownMenuItem(
                      value: priority,
                      child: TodoPriorityBadge(priority: priority),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                onTap: _pickDueDate,
                decoration: InputDecoration(
                  labelText: l10n.dueDate,
                  hintText: l10n.selectDueDate,
                  suffixIcon: _dueDate == null
                      ? const Icon(Icons.calendar_today_outlined)
                      : IconButton(
                          tooltip: l10n.clearDueDate,
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _dueDate = null;
                            _updateDueDateText();
                          }),
                        ),
                ),
              ),
            ],
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
