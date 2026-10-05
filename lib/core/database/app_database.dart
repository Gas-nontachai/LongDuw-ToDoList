import 'package:sqflite/sqflite.dart';

import 'database_platform.dart';

class AppDatabase {
  AppDatabase({this.factory, this.path});

  final DatabaseFactory? factory;
  final String? path;
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    try {
      final selectedFactory = factory ?? appDatabaseFactory;
      final selectedPath = path ?? await getAppDatabasePath();
      return await selectedFactory.openDatabase(
        selectedPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE todos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                details TEXT NOT NULL,
                completed INTEGER NOT NULL DEFAULT 0
                  CHECK (completed IN (0, 1)),
                priority TEXT NOT NULL DEFAULT 'medium',
                created_at TEXT NOT NULL,
                due_date TEXT
              )
            ''');
          },
        ),
      );
    } catch (_) {
      // A failed open must not prevent the UI's retry action from working.
      _opening = null;
      rethrow;
    }
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    try {
      final db = await opening;
      await db.close();
    } finally {
      _opening = null;
    }
  }
}
