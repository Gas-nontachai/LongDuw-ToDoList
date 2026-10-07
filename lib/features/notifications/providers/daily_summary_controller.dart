import 'package:flutter/widgets.dart';

import '../../../app/app_preferences.dart';
import '../../../core/config/dev_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../todo/models/todo.dart';
import '../models/daily_summary.dart';
import '../services/notification_service.dart';

enum DailySummaryIssue { permissionDenied, failed }

enum TestNotificationResult { shown, permissionDenied, failed, unavailable }

/// Serializes settings changes and reconciliation after successful Todo writes.
/// Notification errors never propagate back into a successful Todo operation.
class DailySummaryController extends ChangeNotifier {
  DailySummaryController({
    required this.preferences,
    required this.notifications,
    required this.loadTodos,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppPreferences preferences;
  final NotificationService notifications;
  final Future<List<Todo>> Function() loadTodos;
  final DateTime Function() _now;
  Future<void> _tail = Future.value();
  int _pending = 0;
  bool _disposed = false;
  bool _paused = false;

  /// Stop new lifecycle/provider reconciliations and drain existing work before
  /// restore acquires the shared database gate.
  Future<void> pause() async {
    _paused = true;
    await _tail;
  }

  void resume() {
    _paused = false;
  }

  DailySummaryIssue? issue;

  /// Resolved MaterialApp locale; may differ from the device's primary locale.
  Locale? resolvedLocale;

  bool get supported => notifications.supported;
  bool get enabled => preferences.dailySummaryEnabled;
  int get reminderMinutes => preferences.reminderMinutes;
  bool get busy => _pending > 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _enqueue(
    Future<void> Function() action, {
    bool reportIssue = true,
  }) {
    if (_paused || _disposed) return Future.value();
    _pending++;
    _notify();
    return _tail = _tail.then((_) async {
      if (reportIssue) issue = null;
      try {
        if (_disposed) return;
        await preferences.database.gate.run(action);
      } catch (error, stackTrace) {
        if (reportIssue) issue = DailySummaryIssue.failed;
        debugPrint('Daily Summary update failed: $error\n$stackTrace');
      } finally {
        _pending--;
        _notify();
      }
    });
  }

  Future<void> refresh() => _enqueue(_synchronize);

  Future<AppLocalizations> _loadLocalizations() =>
      AppLocalizations.delegate.load(
        Locale(
          (resolvedLocale ??
                          preferences.locale ??
                          WidgetsBinding.instance.platformDispatcher.locale)
                      .languageCode ==
                  'th'
              ? 'th'
              : 'en',
        ),
      );

  Future<TestNotificationResult> testNotification() async {
    if (!devToolsEnabled || !supported || _disposed) {
      return TestNotificationResult.unavailable;
    }
    var result = TestNotificationResult.failed;
    await _enqueue(() async {
      await notifications.initialize();
      if (!await notifications.hasPermission() &&
          !await notifications.requestPermission()) {
        result = TestNotificationResult.permissionDenied;
        return;
      }
      final l10n = await _loadLocalizations();
      await notifications.showTest(
        l10n.dailySummary,
        l10n.dailySummaryCounts(4, 2),
      );
      result = TestNotificationResult.shown;
    }, reportIssue: false);
    return result;
  }

  Future<void> setEnabled(bool value) => _enqueue(() async {
    if (!supported) return;
    if (value) {
      await notifications.initialize();
      if (!await notifications.hasPermission() &&
          !await notifications.requestPermission()) {
        issue = DailySummaryIssue.permissionDenied;
        return;
      }
    }
    await preferences.saveDailySummaryEnabled(value);
    await _synchronize();
  });

  Future<void> setReminderMinutes(int minutes) => _enqueue(() async {
    await preferences.saveReminderMinutes(minutes);
    await _synchronize();
  });

  Future<void> _synchronize() async {
    if (!supported) return;
    final wasPending = preferences.reconciliationPending;
    final ledger = preferences.summaryLedger;
    // First launch with the feature OFF neither initializes plugins nor prompts.
    if (!enabled && ledger.isEmpty && !wasPending) return;
    await preferences.saveReconciliationPending(true);
    await notifications.initialize();
    final now = _now();
    var consumedDay = preferences.summaryConsumedDay;
    for (final entry in ledger.entries) {
      if (entry.value <= now.millisecondsSinceEpoch &&
          entry.key > consumedDay) {
        consumedDay = entry.key;
      }
    }
    // Conservatively consume elapsed scheduled days, even if OS delivery was
    // delayed. Moving the time later must not create a second alert that day.
    await preferences.saveSummaryConsumedDay(consumedDay);

    final allowed = !enabled || await notifications.hasPermission();
    for (final id in await notifications.pendingIds()) {
      if (DailySummaryRequest.ownsId(id)) await notifications.cancel(id);
    }
    await preferences.saveSummaryLedger({});
    if (!allowed) {
      issue = DailySummaryIssue.permissionDenied;
      return;
    }

    List<DailySummaryRequest> requests = [];
    AppLocalizations? l10n;
    if (enabled && allowed) {
      final todos = await loadTodos(); // Always use persisted, unfiltered data.
      final location = await notifications.getLocation();
      requests = planDailySummaries(
        todos: todos,
        now: now,
        location: location,
        reminderMinutes: reminderMinutes,
        consumedDay: consumedDay,
      );
      l10n = await _loadLocalizations();
    }

    final scheduled = <int, int>{};
    // Persist each success so a partial platform failure can be retried safely.
    for (final request in requests) {
      final summary = request.summary;
      final body = summary.today > 0
          ? l10n!.dailySummaryCounts(summary.today, summary.overdue)
          : summary.overdue > 0
          ? l10n!.dailySummaryOverdue(summary.overdue)
          : l10n!.dailySummaryEmpty;
      await notifications.schedule(request, l10n.dailySummary, body);
      scheduled[request.day] = request.date.millisecondsSinceEpoch;
      await preferences.saveSummaryLedger(scheduled);
    }
    await preferences.saveReconciliationPending(false);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
