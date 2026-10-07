import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ลองดูว - To Do List'**
  String get appTitle;

  /// No description provided for @addTodo.
  ///
  /// In en, this message translates to:
  /// **'Add todo'**
  String get addTodo;

  /// No description provided for @editTodo.
  ///
  /// In en, this message translates to:
  /// **'Edit todo'**
  String get editTodo;

  /// No description provided for @deleteTodoQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete todo?'**
  String get deleteTodoQuestion;

  /// Confirmation message shown before deleting a todo.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\"?'**
  String removeTodoConfirmation(String title);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get enterTitle;

  /// No description provided for @enterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter details'**
  String get enterDetails;

  /// No description provided for @searchTodosHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a search term'**
  String get searchTodosHint;

  /// No description provided for @clearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchTooltip;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @selectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select a due date'**
  String get selectDueDate;

  /// No description provided for @clearDueDate.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get clearDueDate;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @incomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incomplete;

  /// No description provided for @noTodosYet.
  ///
  /// In en, this message translates to:
  /// **'No todos yet. Add one!'**
  String get noTodosYet;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @couldNotLoadTodos.
  ///
  /// In en, this message translates to:
  /// **'Could not load todos.'**
  String get couldNotLoadTodos;

  /// No description provided for @todoAdded.
  ///
  /// In en, this message translates to:
  /// **'Todo added'**
  String get todoAdded;

  /// No description provided for @todoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Todo updated'**
  String get todoUpdated;

  /// No description provided for @todoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Todo deleted'**
  String get todoDeleted;

  /// No description provided for @savingData.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingData;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @addTodoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add todo'**
  String get addTodoTooltip;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @dismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissTooltip;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDarkMode;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @thai.
  ///
  /// In en, this message translates to:
  /// **'ไทย'**
  String get thai;

  /// No description provided for @sortTodosTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort todos'**
  String get sortTodosTooltip;

  /// No description provided for @sortOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original order'**
  String get sortOriginal;

  /// No description provided for @sortTitleAscending.
  ///
  /// In en, this message translates to:
  /// **'Title: A → Z'**
  String get sortTitleAscending;

  /// No description provided for @sortTitleDescending.
  ///
  /// In en, this message translates to:
  /// **'Title: Z → A'**
  String get sortTitleDescending;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @todoId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get todoId;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @viewTodo.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewTodo;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @taskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task remaining} other{{count} tasks remaining}}'**
  String taskCount(int count);

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day remaining} other{{count} days remaining}}'**
  String daysRemaining(int count);

  /// No description provided for @overdueDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String overdueDays(int count);

  /// No description provided for @filterTodos.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTodos;

  /// No description provided for @resetQuery.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetQuery;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters ({count})'**
  String applyFilters(int count);

  /// No description provided for @applySort.
  ///
  /// In en, this message translates to:
  /// **'Apply sorting'**
  String get applySort;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @filterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get filterOverdue;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Within 7 days'**
  String get filterSevenDays;

  /// No description provided for @filterThreeDays.
  ///
  /// In en, this message translates to:
  /// **'Within 3 days'**
  String get filterThreeDays;

  /// No description provided for @duePresenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Due date availability'**
  String get duePresenceTitle;

  /// No description provided for @hasDueDate.
  ///
  /// In en, this message translates to:
  /// **'Has a due date'**
  String get hasDueDate;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @dateRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRangeTitle;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select a date range'**
  String get selectDateRange;

  /// No description provided for @clearDateRange.
  ///
  /// In en, this message translates to:
  /// **'Clear date range'**
  String get clearDateRange;

  /// No description provided for @sortDueAscending.
  ///
  /// In en, this message translates to:
  /// **'Due date: nearest first'**
  String get sortDueAscending;

  /// No description provided for @sortDueDescending.
  ///
  /// In en, this message translates to:
  /// **'Due date: farthest first'**
  String get sortDueDescending;

  /// No description provided for @sortPriorityDescending.
  ///
  /// In en, this message translates to:
  /// **'Priority: high → low'**
  String get sortPriorityDescending;

  /// No description provided for @sortPriorityAscending.
  ///
  /// In en, this message translates to:
  /// **'Priority: low → high'**
  String get sortPriorityAscending;

  /// No description provided for @sortCreatedDescending.
  ///
  /// In en, this message translates to:
  /// **'Created: newest first'**
  String get sortCreatedDescending;

  /// No description provided for @sortCreatedAscending.
  ///
  /// In en, this message translates to:
  /// **'Created: oldest first'**
  String get sortCreatedAscending;

  /// No description provided for @noMatchingTodos.
  ///
  /// In en, this message translates to:
  /// **'No tasks match your search or filters'**
  String get noMatchingTodos;

  /// No description provided for @expandSheet.
  ///
  /// In en, this message translates to:
  /// **'Expand to full screen'**
  String get expandSheet;

  /// No description provided for @collapseSheet.
  ///
  /// In en, this message translates to:
  /// **'Collapse sheet'**
  String get collapseSheet;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummary;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @dailySummaryCounts.
  ///
  /// In en, this message translates to:
  /// **'Today: {today} tasks · Overdue: {overdue}'**
  String dailySummaryCounts(int today, int overdue);

  /// No description provided for @dailySummaryOverdue.
  ///
  /// In en, this message translates to:
  /// **'No tasks today · Overdue: {overdue}'**
  String dailySummaryOverdue(int overdue);

  /// No description provided for @dailySummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks today 🎉 Shall we plan what’s next?'**
  String get dailySummaryEmpty;

  /// No description provided for @dailySummaryUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Available on Android and iOS.'**
  String get dailySummaryUnsupported;

  /// No description provided for @dailySummaryPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Allow notifications in your device settings, then retry.'**
  String get dailySummaryPermissionDenied;

  /// No description provided for @dailySummaryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update reminders. Please retry.'**
  String get dailySummaryFailed;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @testNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Show a sample notification now (dev only).'**
  String get testNotificationDescription;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent. Check your notification center.'**
  String get testNotificationSent;

  /// No description provided for @testNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not show the test notification. Please try again.'**
  String get testNotificationFailed;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @homeOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get homeOverview;

  /// No description provided for @homeNoTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks due today'**
  String get homeNoTasksToday;

  /// No description provided for @homeDueSummary.
  ///
  /// In en, this message translates to:
  /// **'{today} due today · {overdue} overdue'**
  String homeDueSummary(int today, int overdue);

  /// No description provided for @homeCompletedProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} completed'**
  String homeCompletedProgress(int completed, int total);

  /// No description provided for @statsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your productivity overview'**
  String get statsSubtitle;

  /// No description provided for @statsTotalTasks.
  ///
  /// In en, this message translates to:
  /// **'Total tasks'**
  String get statsTotalTasks;

  /// No description provided for @statsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get statsRemaining;

  /// No description provided for @statsCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get statsCompletionRate;

  /// No description provided for @statsByPriority.
  ///
  /// In en, this message translates to:
  /// **'Tasks by priority'**
  String get statsByPriority;

  /// No description provided for @statsByDueDate.
  ///
  /// In en, this message translates to:
  /// **'Tasks by due date'**
  String get statsByDueDate;

  /// No description provided for @statsIncompleteOnly.
  ///
  /// In en, this message translates to:
  /// **'Remaining tasks only'**
  String get statsIncompleteOnly;

  /// No description provided for @statsDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon (1–7 days)'**
  String get statsDueSoon;

  /// No description provided for @statsLater.
  ///
  /// In en, this message translates to:
  /// **'Later (over 7 days)'**
  String get statsLater;

  /// No description provided for @dataAndBackup.
  ///
  /// In en, this message translates to:
  /// **'Data & Backup'**
  String get dataAndBackup;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup data'**
  String get backupData;

  /// No description provided for @backupDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a copy of all app data'**
  String get backupDataSubtitle;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace current data with a backup'**
  String get restoreBackupSubtitle;

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a backup of everything stored in this app.'**
  String get backupDescription;

  /// No description provided for @backupIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get backupIncluded;

  /// No description provided for @backupAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get backupAppSettings;

  /// No description provided for @backupNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get backupNotificationSettings;

  /// No description provided for @backupFileName.
  ///
  /// In en, this message translates to:
  /// **'Backup file'**
  String get backupFileName;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get createBackup;

  /// No description provided for @creatingBackup.
  ///
  /// In en, this message translates to:
  /// **'Creating backup…'**
  String get creatingBackup;

  /// No description provided for @preparingBackup.
  ///
  /// In en, this message translates to:
  /// **'Preparing your data'**
  String get preparingBackup;

  /// No description provided for @savingBackup.
  ///
  /// In en, this message translates to:
  /// **'Save backup'**
  String get savingBackup;

  /// No description provided for @selectBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Select a backup file'**
  String get selectBackupFile;

  /// No description provided for @checkingBackup.
  ///
  /// In en, this message translates to:
  /// **'Checking backup…'**
  String get checkingBackup;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get backupCreated;

  /// No description provided for @backupCreatedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your data has been backed up successfully.'**
  String get backupCreatedDescription;

  /// No description provided for @backupDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get backupDone;

  /// No description provided for @backupCreatedDate.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get backupCreatedDate;

  /// No description provided for @backupContains.
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get backupContains;

  /// No description provided for @restoreReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data on this device.'**
  String get restoreReplaceWarning;

  /// No description provided for @backupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get backupContinue;

  /// No description provided for @replaceCurrentData.
  ///
  /// In en, this message translates to:
  /// **'Replace current data?'**
  String get replaceCurrentData;

  /// No description provided for @replaceCurrentDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Restoring this backup will delete all current tasks and settings and replace them with this backup.'**
  String get replaceCurrentDataDescription;

  /// No description provided for @restoreCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get restoreCannotUndo;

  /// No description provided for @replaceAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Replace & restore'**
  String get replaceAndRestore;

  /// No description provided for @restoringBackup.
  ///
  /// In en, this message translates to:
  /// **'Restoring backup…'**
  String get restoringBackup;

  /// No description provided for @restoreKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Please keep the app open.'**
  String get restoreKeepOpen;

  /// No description provided for @restoreTasksStage.
  ///
  /// In en, this message translates to:
  /// **'Replacing tasks'**
  String get restoreTasksStage;

  /// No description provided for @restoreSettingsStage.
  ///
  /// In en, this message translates to:
  /// **'Replacing settings'**
  String get restoreSettingsStage;

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restoreComplete;

  /// No description provided for @restoreCompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Your data has been restored successfully.'**
  String get restoreCompleteDescription;

  /// No description provided for @restoreAppSettingsComplete.
  ///
  /// In en, this message translates to:
  /// **'App settings restored'**
  String get restoreAppSettingsComplete;

  /// No description provided for @restoreNotificationsComplete.
  ///
  /// In en, this message translates to:
  /// **'Notification settings restored'**
  String get restoreNotificationsComplete;

  /// No description provided for @backupGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get backupGoHome;

  /// No description provided for @invalidBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to restore backup'**
  String get invalidBackupTitle;

  /// No description provided for @invalidBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'This backup file is invalid or corrupted. Your current data has not been changed.'**
  String get invalidBackupDescription;

  /// No description provided for @unsupportedBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup not supported'**
  String get unsupportedBackupTitle;

  /// No description provided for @unsupportedBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'This backup was created using an unsupported version of the app. Your current data has not been changed.'**
  String get unsupportedBackupDescription;

  /// No description provided for @restoreFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get restoreFailedTitle;

  /// No description provided for @restoreFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t restore this backup. Your previous data has been kept.'**
  String get restoreFailedDescription;

  /// No description provided for @chooseAnotherBackup.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get chooseAnotherBackup;

  /// No description provided for @backupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to create backup'**
  String get backupFailedTitle;

  /// No description provided for @backupFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t create or save your backup. Please try again.'**
  String get backupFailedDescription;

  /// No description provided for @restoreRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Your data was restored, but the app could not reload it. Please retry.'**
  String get restoreRefreshFailed;

  /// No description provided for @backupTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String backupTaskCount(int count);

  /// No description provided for @restoreTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task restored} other{{count} tasks restored}}'**
  String restoreTaskCount(int count);

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get settingsAbout;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @dataAndBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Back up and restore your data'**
  String get dataAndBackupSubtitle;

  /// No description provided for @backupOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep a copy of your data'**
  String get backupOverviewTitle;

  /// No description provided for @backupOverviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Save a backup file to restore your tasks and settings later.'**
  String get backupOverviewDescription;

  /// No description provided for @backupTasksDescription.
  ///
  /// In en, this message translates to:
  /// **'All completed and remaining tasks'**
  String get backupTasksDescription;

  /// No description provided for @backupAppSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Theme and language'**
  String get backupAppSettingsDescription;

  /// No description provided for @backupNotificationSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily summary and reminder time'**
  String get backupNotificationSettingsDescription;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Organize your tasks,\nkeep things simple,\nand see the whole picture.'**
  String get onboardingWelcome;

  /// No description provided for @onboardingBenefitOrganize.
  ///
  /// In en, this message translates to:
  /// **'Organize tasks easily'**
  String get onboardingBenefitOrganize;

  /// No description provided for @onboardingBenefitOverview.
  ///
  /// In en, this message translates to:
  /// **'See what needs doing'**
  String get onboardingBenefitOverview;

  /// No description provided for @onboardingBenefitHabit.
  ///
  /// In en, this message translates to:
  /// **'Build a daily habit'**
  String get onboardingBenefitHabit;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboardingSkipAll.
  ///
  /// In en, this message translates to:
  /// **'Skip introduction'**
  String get onboardingSkipAll;

  /// No description provided for @onboardingPersonalize.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get onboardingPersonalize;

  /// No description provided for @onboardingPersonalizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your language and a comfortable theme.'**
  String get onboardingPersonalizeDescription;

  /// No description provided for @onboardingChangeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change these later in Settings.'**
  String get onboardingChangeLater;

  /// No description provided for @onboardingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onboardingLanguage;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appTheme;

  /// No description provided for @appThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appThemeSystem;

  /// No description provided for @appThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appThemeLight;

  /// No description provided for @appThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appThemeDark;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingLater;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily summary'**
  String get onboardingSummaryTitle;

  /// No description provided for @onboardingSummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Get a daily overview of today’s and overdue tasks at your chosen time.'**
  String get onboardingSummaryDescription;

  /// No description provided for @onboardingSummaryScope.
  ///
  /// In en, this message translates to:
  /// **'A daily overview, rather than individual task reminders.'**
  String get onboardingSummaryScope;

  /// No description provided for @onboardingSummaryEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable daily summary'**
  String get onboardingSummaryEnable;

  /// No description provided for @onboardingSummaryEnabled.
  ///
  /// In en, this message translates to:
  /// **'Daily summary is enabled'**
  String get onboardingSummaryEnabled;

  /// No description provided for @onboardingSummaryEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'You can change the reminder time later in Settings.'**
  String get onboardingSummaryEnabledDescription;

  /// No description provided for @onboardingSummaryDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not enabled'**
  String get onboardingSummaryDenied;

  /// No description provided for @onboardingFirstTask.
  ///
  /// In en, this message translates to:
  /// **'Create your first task'**
  String get onboardingFirstTask;

  /// No description provided for @onboardingFirstTaskDescription.
  ///
  /// In en, this message translates to:
  /// **'Add something you want to do today. Start with something small.'**
  String get onboardingFirstTaskDescription;

  /// No description provided for @onboardingTaskHint.
  ///
  /// In en, this message translates to:
  /// **'For example, read a book'**
  String get onboardingTaskHint;

  /// No description provided for @onboardingAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add first task'**
  String get onboardingAddTask;

  /// No description provided for @onboardingTaskAdded.
  ///
  /// In en, this message translates to:
  /// **'Your first task is added!'**
  String get onboardingTaskAdded;

  /// No description provided for @onboardingTaskAddedDescription.
  ///
  /// In en, this message translates to:
  /// **'A great start 🎉\nLet’s take it one task at a time.'**
  String get onboardingTaskAddedDescription;

  /// No description provided for @onboardingEnterApp.
  ///
  /// In en, this message translates to:
  /// **'Start using the app'**
  String get onboardingEnterApp;

  /// No description provided for @onboardingReplay.
  ///
  /// In en, this message translates to:
  /// **'View introduction again'**
  String get onboardingReplay;

  /// No description provided for @onboardingProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingProgress(int step, int total);

  /// No description provided for @onboardingSummaryWorking.
  ///
  /// In en, this message translates to:
  /// **'Preparing notifications…'**
  String get onboardingSummaryWorking;

  /// No description provided for @softwareLicenses.
  ///
  /// In en, this message translates to:
  /// **'Software licenses'**
  String get softwareLicenses;

  /// No description provided for @backupPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Backup files are not encrypted. Anyone with the file can read your tasks and settings. Save it somewhere private and share it only with people you trust.'**
  String get backupPrivacyNotice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
