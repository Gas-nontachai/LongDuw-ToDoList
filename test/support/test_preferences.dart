import 'package:longdow_todo_list/app/app_preferences.dart';
import 'package:longdow_todo_list/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Real SQLite without an isolate so operations work under widget fake clocks.
class TestPreferences {
  TestPreferences() {
    sqfliteFfiInit();
  }
  final database = AppDatabase(
    factory: databaseFactoryFfiNoIsolate,
    path: inMemoryDatabasePath,
  );
  final _instances = <AppPreferences>[];
  Future<AppPreferences> load({bool completeOnboarding = true}) async {
    await database.database;
    final preferences = await AppPreferences.load(database: database);
    if (completeOnboarding) await preferences.completeOnboarding();
    _instances.add(preferences);
    return preferences;
  }

  AppPreferences get preferences => _instances.last;
  Future<void> close() async {
    for (final preferences in _instances) {
      preferences.dispose();
    }
    await database.close();
  }
}
