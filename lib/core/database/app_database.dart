import 'package:sqflite/sqflite.dart';

import 'database_platform.dart';
import 'operation_gate.dart';

class AppDatabase {
  AppDatabase({this.factory, this.path});

  static const schemaVersion = 2;
  final gate = OperationGate();

  /// True only when this connection created a new database.
  bool wasCreated = false;

  final DatabaseFactory? factory;
  final String? path;
  Future<Database>? _opening;
  Database? _connection;

  Future<Database> get database =>
      _connection != null ? Future.value(_connection) : (_opening ??= _open());

  Future<Database> _open() async {
    try {
      wasCreated = false;
      final selectedFactory = factory ?? appDatabaseFactory;
      final selectedPath = path ?? await getAppDatabasePath();
      final db = await selectedFactory.openDatabase(
        selectedPath,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onCreate: (db, version) async {
            wasCreated = true;
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
            await _createSettings(db);
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) await _createSettings(db);
          },
        ),
      );
      _connection = db;
      return db;
    } catch (_) {
      // A failed open must not prevent the UI's retry action from working.
      _opening = null;
      rethrow;
    }
  }

  static Future<void> _createSettings(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE notification_runtime (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE app_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    try {
      final db = _connection ?? await opening;
      await db.close();
    } finally {
      _connection = null;
      _opening = null;
    }
  }
}
