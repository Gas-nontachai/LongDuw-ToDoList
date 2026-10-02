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
}
