import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/config/priority_config.dart';
import '../../../core/database/app_database.dart';

enum BackupFailure { invalid, unsupported }

class BackupException implements Exception {
  const BackupException(this.failure);
  final BackupFailure failure;
}

/// Only the codec can construct this immutable, fully checked restore input.
class ValidatedBackup {
  ValidatedBackup._(
    this.createdAt,
    this.appVersion,
    this.todos,
    this.appSettings,
    this.notificationSettings,
  );
  final DateTime createdAt;
  final String appVersion;
  final List<Map<String, Object?>> todos;
  final Map<String, Object?> appSettings;
  final Map<String, Object?> notificationSettings;
  int get taskCount => todos.length;
}

class BackupCodec {
  const BackupCodec();
  static const identifier = 'todo_app_backup';
  static const version = 1;

  Uint8List encode({
    required DateTime createdAt,
    required String appVersion,
    required List<Map<String, Object?>> todos,
    required Map<String, Object?> appSettings,
    required Map<String, Object?> notificationSettings,
  }) {
    final content = <String, Object?>{
      'format': identifier,
      'backupVersion': version,
      'databaseVersion': AppDatabase.schemaVersion,
      'appVersion': appVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'payload': {
        'todos': todos,
        'appSettings': appSettings,
        'notificationSettings': notificationSettings,
      },
    };
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          ...content,
          'checksum': sha256
              .convert(utf8.encode(_canonical(content)))
              .toString(),
        }),
      ),
    );
    // Never export a package that this version cannot restore.
    decode(bytes);
    return bytes;
  }

  ValidatedBackup decode(Uint8List bytes) {
    try {
      final envelope = _map(jsonDecode(utf8.decode(bytes)));
      _keys(envelope, {
        'format',
        'backupVersion',
        'databaseVersion',
        'appVersion',
        'createdAt',
        'payload',
        'checksum',
      });
      _require(envelope['format'] == identifier);
      _require(
        envelope['backupVersion'] is int && envelope['databaseVersion'] is int,
      );
      _require(
        envelope['appVersion'] is String &&
            (envelope['appVersion'] as String).isNotEmpty,
      );
      final createdAt = _date(envelope['createdAt'], utc: true);
      _require(envelope['checksum'] is String);
      final content = Map<String, Object?>.from(envelope)..remove('checksum');
      _require(
        envelope['checksum'] ==
            sha256.convert(utf8.encode(_canonical(content))).toString(),
      );
      if (envelope['backupVersion'] != version ||
          envelope['databaseVersion'] != AppDatabase.schemaVersion) {
        throw const BackupException(BackupFailure.unsupported);
      }
      return _decodeV1(
        _map(envelope['payload']),
        createdAt,
        envelope['appVersion'] as String,
      );
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(BackupFailure.invalid);
    }
  }

  ValidatedBackup _decodeV1(
    Map<String, Object?> payload,
    DateTime createdAt,
    String appVersion,
  ) {
    _keys(payload, {'todos', 'appSettings', 'notificationSettings'});
    final rawTodos = payload['todos'];
    _require(rawTodos is List);
    final ids = <int>{};
    final todos = <Map<String, Object?>>[];
    for (final raw in rawTodos as List) {
      final row = _map(raw);
      _keys(row, {
        'id',
        'title',
        'details',
        'completed',
        'priority',
        'created_at',
        'due_date',
      });
      final id = row['id'];
      _require(id is int && id > 0);
      _require(ids.add(id as int));
      _require(
        row['title'] is String &&
            row['details'] is String &&
            row['completed'] is bool,
      );
      _require(PriorityConfig.values.contains(row['priority']));
      _date(row['created_at']);
      if (row['due_date'] != null) _date(row['due_date']);
      todos.add(Map.unmodifiable(row));
    }
    final app = _map(payload['appSettings']);
    _keys(app, {'themeMode', 'languageCode'});
    _require({'system', 'light', 'dark'}.contains(app['themeMode']));
    _require(
      app['languageCode'] == null || {'en', 'th'}.contains(app['languageCode']),
    );
    final notifications = _map(payload['notificationSettings']);
    _keys(notifications, {'dailySummaryEnabled', 'reminderMinutes'});
    _require(notifications['dailySummaryEnabled'] is bool);
    final minutes = notifications['reminderMinutes'];
    _require(minutes is int && minutes >= 0 && minutes < 1440);
    return ValidatedBackup._(
      createdAt,
      appVersion,
      List.unmodifiable(todos),
      Map.unmodifiable(app),
      Map.unmodifiable(notifications),
    );
  }

  static void _require(bool condition) {
    if (!condition) throw const BackupException(BackupFailure.invalid);
  }

  static Map<String, Object?> _map(Object? value) {
    _require(value is Map<String, dynamic>);
    return Map<String, Object?>.from(value as Map);
  }

  static void _keys(Map<String, Object?> value, Set<String> keys) {
    _require(value.length == keys.length && keys.every(value.containsKey));
  }

  static DateTime _date(Object? value, {bool utc = false}) {
    _require(value is String);
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?(?:Z|[+-]\d{2}:\d{2})?$',
    ).firstMatch(value as String);
    _require(match != null);
    final year = int.parse(match![1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    _require(
      month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= DateTime.utc(year, month + 1, 0).day,
    );
    _require(
      int.parse(match[4]!) < 24 &&
          int.parse(match[5]!) < 60 &&
          int.parse(match[6]!) < 60,
    );
    final offset = RegExp(r'[+-](\d{2}):(\d{2})$').firstMatch(value);
    if (offset != null) {
      _require(int.parse(offset[1]!) < 24 && int.parse(offset[2]!) < 60);
    }
    if (utc) _require(value.endsWith('Z'));
    final parsed = DateTime.tryParse(value);
    _require(parsed != null);
    return parsed!;
  }

  static String _canonical(Object? value) => jsonEncode(_sorted(value));
  static Object? _sorted(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _sorted(value[key])};
    }
    if (value is List) return value.map(_sorted).toList();
    return value;
  }
}
