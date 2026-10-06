import 'dart:typed_data';

import 'package:longdow_todo_list/features/backup/services/backup_file_gateway.dart';

class FakeBackupFiles implements BackupFileGateway {
  @override
  bool supported = true;
  PickedBackupFile? selected;
  Uint8List? savedBytes;
  String? savedName;
  bool saveResult = true;
  bool failSave = false;
  int saves = 0;
  @override
  Future<PickedBackupFile?> pick() async => selected;
  @override
  Future<bool> save(String name, Uint8List bytes) async {
    saves++;
    if (failSave) throw StateError('save failed');
    savedName = name;
    savedBytes = bytes;
    return saveResult;
  }
}
