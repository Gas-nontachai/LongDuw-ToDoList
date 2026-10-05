import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

DatabaseFactory get appDatabaseFactory {
  if (Platform.isWindows || Platform.isLinux) {
    ffi.sqfliteFfiInit();
    return ffi.databaseFactoryFfi;
  }
  return databaseFactory;
}

Future<String> getAppDatabasePath() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return p.join(directory.path, 'todos.db');
}
