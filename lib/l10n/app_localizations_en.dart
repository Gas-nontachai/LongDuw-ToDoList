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
  String get enterTitle => 'Enter a title';

  @override
  String get status => 'Status';

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
  String get english => 'English';

  @override
  String get thai => 'ไทย';
}
