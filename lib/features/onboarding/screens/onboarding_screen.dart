import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_preferences.dart';
import '../../../core/config/priority_config.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design/app_icon_assets.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/app_theme_selector.dart';
import '../../notifications/providers/daily_summary_controller.dart';
import '../../todo/models/todo.dart';
import '../../todo/widgets/todo_form_fields.dart';
import '../../todo/providers/todo_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.preferences,
    required this.notifications,
    required this.onFinished,
  });

  final AppPreferences preferences;
  final DailySummaryController notifications;
  final VoidCallback onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late int _step;
  bool _busy = false;
  bool _failed = false;
  bool _notificationAttempted = false;
  bool _permissionDenied = false;
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _dueDateText = TextEditingController();
  final _scroll = ScrollController();
  final _form = GlobalKey<FormState>();
  DateTime? _dueDate = DateUtils.dateOnly(DateTime.now());
  String _priority = PriorityConfig.medium;
  Todo? _created;

  @override
  void initState() {
    super.initState();
    _step = widget.preferences.onboardingStep;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDueDateText();
  }

  void _updateDueDateText() {
    _dueDateText.text = DateTimeUtils.formatDate(
      _dueDate,
      localizations: MaterialLocalizations.of(context),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _dueDateText.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || widget.notifications.busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await action();
    } catch (error, stack) {
      debugPrint('Onboarding action failed: $error\n$stack');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _go(int step) => _run(() async {
    FocusScope.of(context).unfocus();
    if (step == 3 &&
        (await ref.read(todoServiceProvider).getTodos()).isNotEmpty) {
      await _finish();
      return;
    }
    await widget.preferences.saveOnboardingStep(step);
    if (mounted) {
      setState(() => _step = step);
      _scrollToTop();
    }
  });

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  Future<void> _finish() async {
    await widget.preferences.completeOnboarding();
    if (mounted) widget.onFinished();
  }

  Future<void> _addTask() async {
    if (!_form.currentState!.validate()) return;
    await _run(() async {
      final created = await ref
          .read(todoServiceProvider)
          .createOnboardingTodo(
            _title.text,
            details: _details.text.trim(),
            priority: _priority,
            dueDate: _dueDate,
          );
      // The transaction has committed. Never offer another create, even if a
      // subsequent cache reload fails.
      if (mounted) {
        setState(() => _created = created);
        _scrollToTop();
      }
      ref.invalidate(todoProvider);
      await widget.preferences.reload();
      await widget.notifications.refresh();
    });
  }

  Future<void> _pickTime() => _run(() async {
    final minutes = widget.notifications.reminderMinutes;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null) {
      await widget.notifications.setReminderMinutes(
        time.hour * 60 + time.minute,
      );
    }
  });

  Future<void> _pickDate() => _run(() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() {
        _dueDate = selected;
        _updateDueDateText();
      });
    }
  });

  Widget _heading(String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Text(description, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 24),
    ],
  );

  Widget _primary(String label, VoidCallback action, bool busy) => SizedBox(
    width: double.infinity,
    child: FilledButton(onPressed: busy ? null : action, child: Text(label)),
  );

  Widget _secondary(String label, VoidCallback action, bool busy) =>
      TextButton(onPressed: busy ? null : action, child: Text(label));

  Widget _symbol(IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: CircleAvatar(
      radius: 36,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
    ),
  );

  List<Widget> _welcome(AppLocalizations l10n, bool busy) => [
    const SizedBox(height: 24),
    const Center(child: AppIcon.asset(AppIconAssets.logo, size: 96)),
    const SizedBox(height: 28),
    Text(
      l10n.appTitle,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 16),
    Text(
      l10n.onboardingWelcome,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge,
    ),
    const SizedBox(height: 24),
    Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.checklist),
            title: Text(l10n.onboardingBenefitOrganize),
          ),
          ListTile(
            leading: const Icon(Icons.today_outlined),
            title: Text(l10n.onboardingBenefitOverview),
          ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: Text(l10n.onboardingBenefitHabit),
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    _primary(l10n.onboardingStart, () => _go(1), busy),
    _secondary(l10n.onboardingSkipAll, () => _run(_finish), busy),
  ];

  List<Widget> _personalize(AppLocalizations l10n, bool busy) => [
    _heading(l10n.onboardingPersonalize, l10n.onboardingPersonalizeDescription),
    Text(
      l10n.onboardingLanguage,
      style: Theme.of(context).textTheme.titleMedium,
    ),
    const SizedBox(height: 8),
    for (final language in ['th', 'en'])
      Card(
        child: ListTile(
          title: Text(language == 'th' ? l10n.thai : l10n.english),
          selected: Localizations.localeOf(context).languageCode == language,
          trailing: Icon(
            Localizations.localeOf(context).languageCode == language
                ? Icons.check_circle
                : Icons.circle_outlined,
          ),
          onTap: busy
              ? null
              : () =>
                    _run(() => widget.preferences.saveLocale(Locale(language))),
        ),
      ),
    const SizedBox(height: 24),
    Text(l10n.appTheme, style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 12),
    AppThemeSelector(
      value: widget.preferences.themeMode,
      onChanged: busy
          ? null
          : (mode) => _run(() => widget.preferences.saveThemeMode(mode)),
    ),
    const SizedBox(height: 16),
    Text(l10n.onboardingChangeLater),
    const SizedBox(height: 32),
    _primary(l10n.onboardingNext, () => _go(2), busy),
  ];

  List<Widget> _summary(AppLocalizations l10n, bool busy) {
    final controller = widget.notifications;
    final issue =
        controller.issue ??
        (!controller.enabled && _permissionDenied
            ? DailySummaryIssue.permissionDenied
            : null);
    final success = controller.enabled && issue == null && !controller.busy;
    final result =
        _notificationAttempted || controller.enabled || issue != null;
    final minutes = controller.reminderMinutes;
    final time =
        '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
    return [
      Center(child: _symbol(Icons.notifications_active_outlined)),
      _heading(l10n.onboardingSummaryTitle, l10n.onboardingSummaryDescription),
      Card(
        child: ListTile(
          leading: const Icon(Icons.schedule),
          title: Text(l10n.reminderTime),
          trailing: Text(time),
          onTap: busy || !controller.supported ? null : _pickTime,
        ),
      ),
      const SizedBox(height: 16),
      Text(l10n.onboardingSummaryScope),
      const SizedBox(height: 24),
      if (!controller.supported) ...[
        Text(l10n.dailySummaryUnsupported),
        const SizedBox(height: 16),
        _primary(l10n.onboardingNext, () => _go(3), busy),
      ] else if (busy) ...[
        Text(l10n.onboardingSummaryWorking),
      ] else if (result) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.info_outline,
                  color: success
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  success
                      ? l10n.onboardingSummaryEnabled
                      : issue == DailySummaryIssue.permissionDenied
                      ? l10n.onboardingSummaryDenied
                      : l10n.dailySummaryFailed,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  success
                      ? l10n.onboardingSummaryEnabledDescription
                      : issue == DailySummaryIssue.permissionDenied
                      ? l10n.dailySummaryPermissionDenied
                      : l10n.dailySummaryFailed,
                ),
                if (issue == DailySummaryIssue.failed)
                  _secondary(
                    l10n.retry,
                    () => _run(() async {
                      if (controller.enabled) {
                        await controller.refresh();
                      } else {
                        await controller.setEnabled(true);
                      }
                    }),
                    busy,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _primary(l10n.onboardingNext, () => _go(3), busy),
      ] else ...[
        _primary(
          l10n.onboardingSummaryEnable,
          () => _run(() async {
            setState(() => _notificationAttempted = true);
            await controller.setEnabled(true);
            if (mounted) {
              setState(() {
                _permissionDenied =
                    controller.issue == DailySummaryIssue.permissionDenied;
              });
            }
          }),
          busy,
        ),
        _secondary(l10n.onboardingLater, () => _go(3), busy),
      ],
    ];
  }

  List<Widget> _firstTask(AppLocalizations l10n, bool busy) => [
    _heading(l10n.onboardingFirstTask, l10n.onboardingFirstTaskDescription),
    Form(
      key: _form,
      child: TodoFormFields(
        titleFieldKey: const ValueKey('onboarding_task_title'),
        titleHint: l10n.onboardingTaskHint,
        titleController: _title,
        detailsController: _details,
        dueDateController: _dueDateText,
        priority: _priority,
        dueDate: _dueDate,
        enabled: !busy,
        onPriorityChanged: (value) => setState(() => _priority = value),
        onPickDueDate: _pickDate,
        onClearDueDate: () => setState(() {
          _dueDate = null;
          _updateDueDateText();
        }),
        onSubmit: _addTask,
      ),
    ),
    const SizedBox(height: 32),
    _primary(l10n.onboardingAddTask, _addTask, busy),
    _secondary(l10n.onboardingSkip, () => _run(_finish), busy),
  ];

  List<Widget> _success(AppLocalizations l10n, bool busy) => [
    const SizedBox(height: 24),
    Center(child: _symbol(Icons.check)),
    _heading(l10n.onboardingTaskAdded, l10n.onboardingTaskAddedDescription),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _created!.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              _created!.dueDate == null
                  ? l10n.noDueDate
                  : MaterialLocalizations.of(context)
                        .formatMediumDate(_created!.dueDate!),
            ),
            const SizedBox(height: 8),
            Text(PriorityConfig.options(l10n)[_created!.priority]!),
          ],
        ),
      ),
    ),
    const SizedBox(height: 32),
    _primary(l10n.onboardingEnterApp, () => _run(_finish), busy),
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.notifications,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context)!;
      final busy = _busy || widget.notifications.busy;
      final canBack = _step > 0 && _created == null && !busy;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && canBack) _go(_step - 1);
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: canBack
                                ? BackButton(onPressed: () => _go(_step - 1))
                                : null,
                          ),
                          Expanded(
                            child: Semantics(
                              label: l10n.onboardingProgress(_step + 1, 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var index = 0; index < 4; index++)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: index <= _step
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_created != null)
                        ..._success(l10n, busy)
                      else
                        ...switch (_step) {
                          0 => _welcome(l10n, busy),
                          1 => _personalize(l10n, busy),
                          2 => _summary(l10n, busy),
                          _ => _firstTask(l10n, busy),
                        },
                      if (busy)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_failed)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            l10n.somethingWentWrong,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
