// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Todo List';

  @override
  String get addTodo => 'Add todo';

  @override
  String get editTodo => 'Edit todo';

  @override
  String get deleteTodoQuestion => 'Delete todo?';

  @override
  String removeTodoConfirmation(String title) {
    return 'Remove \"$title\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get title => 'Title';

  @override
  String get details => 'Details';

  @override
  String get enterTitle => 'Enter a title';

  @override
  String get enterDetails => 'Enter details';

  @override
  String get searchTodosHint => 'Enter a search term';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String get status => 'Status';

  @override
  String get priority => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get dueDate => 'Due date';

  @override
  String get selectDueDate => 'Select a due date';

  @override
  String get clearDueDate => 'Clear due date';

  @override
  String get all => 'All';

  @override
  String get completed => 'Completed';

  @override
  String get incomplete => 'Incomplete';

  @override
  String get noTodosYet => 'No todos yet. Add one!';

  @override
  String get retry => 'Retry';

  @override
  String get couldNotLoadTodos => 'Could not load todos.';

  @override
  String get todoAdded => 'Todo added';

  @override
  String get todoUpdated => 'Todo updated';

  @override
  String get todoDeleted => 'Todo deleted';

  @override
  String get savingData => 'Saving...';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get addTodoTooltip => 'Add todo';

  @override
  String get editTooltip => 'Edit';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get dismissTooltip => 'Dismiss';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get switchToLightMode => 'Switch to light mode';

  @override
  String get switchToDarkMode => 'Switch to dark mode';

  @override
  String get english => 'English';

  @override
  String get thai => 'ไทย';

  @override
  String get sortTodosTooltip => 'Sort todos';

  @override
  String get sortOriginal => 'Original order';

  @override
  String get sortTitleAscending => 'Title: A → Z';

  @override
  String get sortTitleDescending => 'Title: Z → A';

  @override
  String get createdAt => 'Created at';

  @override
  String get todoId => 'ID';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get viewTodo => 'View';

  @override
  String get moreActions => 'More actions';

  @override
  String taskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks remaining',
      one: '1 task remaining',
    );
    return '$_temp0';
  }

  @override
  String get dueToday => 'Due today';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days remaining',
      one: '1 day remaining',
    );
    return '$_temp0';
  }

  @override
  String overdueDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get filterTodos => 'Filter';

  @override
  String get resetQuery => 'Reset';

  @override
  String applyFilters(int count) {
    return 'Apply filters ($count)';
  }

  @override
  String get applySort => 'Apply sorting';

  @override
  String get sortBy => 'Sort by';

  @override
  String get filterOverdue => 'Overdue';

  @override
  String get filterToday => 'Today';

  @override
  String get filterSevenDays => 'Within 7 days';

  @override
  String get filterThreeDays => 'Within 3 days';

  @override
  String get duePresenceTitle => 'Due date availability';

  @override
  String get hasDueDate => 'Has a due date';

  @override
  String get noDueDate => 'No due date';

  @override
  String get dateRangeTitle => 'Date range';

  @override
  String get selectDateRange => 'Select a date range';

  @override
  String get clearDateRange => 'Clear date range';

  @override
  String get sortDueAscending => 'Due date: nearest first';

  @override
  String get sortDueDescending => 'Due date: farthest first';

  @override
  String get sortPriorityDescending => 'Priority: high → low';

  @override
  String get sortPriorityAscending => 'Priority: low → high';

  @override
  String get sortCreatedDescending => 'Created: newest first';

  @override
  String get sortCreatedAscending => 'Created: oldest first';

  @override
  String get noMatchingTodos => 'No tasks match your search or filters';

  @override
  String get expandSheet => 'Expand to full screen';

  @override
  String get collapseSheet => 'Collapse sheet';

  @override
  String get navHome => 'Home';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get dailySummary => 'Daily Summary';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String dailySummaryCounts(int today, int overdue) {
    return 'Today: $today tasks · Overdue: $overdue';
  }

  @override
  String dailySummaryOverdue(int overdue) {
    return 'No tasks today · Overdue: $overdue';
  }

  @override
  String get dailySummaryEmpty =>
      'No tasks today 🎉 Shall we plan what’s next?';

  @override
  String get dailySummaryUnsupported => 'Available on Android and iOS.';

  @override
  String get dailySummaryPermissionDenied =>
      'Notifications are blocked. Allow notifications in your device settings, then retry.';

  @override
  String get dailySummaryFailed => 'Could not update reminders. Please retry.';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get testNotificationDescription =>
      'Show a sample notification now (dev only).';

  @override
  String get testNotificationSent =>
      'Test notification sent. Check your notification center.';

  @override
  String get testNotificationFailed =>
      'Could not show the test notification. Please try again.';

  @override
  String get homeToday => 'Today';

  @override
  String get homeViewAll => 'View all';

  @override
  String get homeOverview => 'Overview';

  @override
  String get homeNoTasksToday => 'No tasks due today';

  @override
  String homeDueSummary(int today, int overdue) {
    return '$today due today · $overdue overdue';
  }

  @override
  String homeCompletedProgress(int completed, int total) {
    return '$completed of $total completed';
  }

  @override
  String get statsSubtitle => 'Your productivity overview';

  @override
  String get statsTotalTasks => 'Total tasks';

  @override
  String get statsRemaining => 'Remaining';

  @override
  String get statsCompletionRate => 'Completion rate';

  @override
  String get statsByPriority => 'Tasks by priority';

  @override
  String get statsByDueDate => 'Tasks by due date';

  @override
  String get statsIncompleteOnly => 'Remaining tasks only';

  @override
  String get statsDueSoon => 'Due soon (1–7 days)';

  @override
  String get statsLater => 'Later (over 7 days)';

  @override
  String get dataAndBackup => 'Data & Backup';

  @override
  String get backupData => 'Backup data';

  @override
  String get backupDataSubtitle => 'Create a copy of all app data';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get restoreBackupSubtitle => 'Replace current data with a backup';

  @override
  String get backupDescription =>
      'Create a backup of everything stored in this app.';

  @override
  String get backupIncluded => 'Included';

  @override
  String get backupAppSettings => 'App settings';

  @override
  String get backupNotificationSettings => 'Notification settings';

  @override
  String get backupFileName => 'Backup file';

  @override
  String get createBackup => 'Create backup';

  @override
  String get creatingBackup => 'Creating backup…';

  @override
  String get preparingBackup => 'Preparing your data';

  @override
  String get savingBackup => 'Save backup';

  @override
  String get selectBackupFile => 'Select a backup file';

  @override
  String get checkingBackup => 'Checking backup…';

  @override
  String get backupCreated => 'Backup created';

  @override
  String get backupCreatedDescription =>
      'Your data has been backed up successfully.';

  @override
  String get backupDone => 'Done';

  @override
  String get backupCreatedDate => 'Created';

  @override
  String get backupContains => 'Contains';

  @override
  String get restoreReplaceWarning =>
      'This will replace all current data on this device.';

  @override
  String get backupContinue => 'Continue';

  @override
  String get replaceCurrentData => 'Replace current data?';

  @override
  String get replaceCurrentDataDescription =>
      'Restoring this backup will delete all current tasks and settings and replace them with this backup.';

  @override
  String get restoreCannotUndo => 'This action cannot be undone.';

  @override
  String get replaceAndRestore => 'Replace & restore';

  @override
  String get restoringBackup => 'Restoring backup…';

  @override
  String get restoreKeepOpen => 'Please keep the app open.';

  @override
  String get restoreTasksStage => 'Replacing tasks';

  @override
  String get restoreSettingsStage => 'Replacing settings';

  @override
  String get restoreComplete => 'Restore complete';

  @override
  String get restoreCompleteDescription =>
      'Your data has been restored successfully.';

  @override
  String get restoreAppSettingsComplete => 'App settings restored';

  @override
  String get restoreNotificationsComplete => 'Notification settings restored';

  @override
  String get backupGoHome => 'Go to Home';

  @override
  String get invalidBackupTitle => 'Unable to restore backup';

  @override
  String get invalidBackupDescription =>
      'This backup file is invalid or corrupted. Your current data has not been changed.';

  @override
  String get unsupportedBackupTitle => 'Backup not supported';

  @override
  String get unsupportedBackupDescription =>
      'This backup was created using an unsupported version of the app. Your current data has not been changed.';

  @override
  String get restoreFailedTitle => 'Restore failed';

  @override
  String get restoreFailedDescription =>
      'We couldn’t restore this backup. Your previous data has been kept.';

  @override
  String get chooseAnotherBackup => 'Choose another file';

  @override
  String get backupFailedTitle => 'Unable to create backup';

  @override
  String get backupFailedDescription =>
      'We couldn’t create or save your backup. Please try again.';

  @override
  String get restoreRefreshFailed =>
      'Your data was restored, but the app could not reload it. Please retry.';

  @override
  String backupTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String restoreTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks restored',
      one: '1 task restored',
    );
    return '$_temp0';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppVersion => 'App version';
}
