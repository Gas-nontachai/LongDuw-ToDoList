import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PickedBackupFile {
  const PickedBackupFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

abstract class BackupFileGateway {
  bool get supported;
  Future<PickedBackupFile?> pick();

  /// True only when the OS confirms save; false means cancellation.
  Future<bool> save(String name, Uint8List bytes);
}

class NativeBackupFileGateway implements BackupFileGateway {
  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<PickedBackupFile?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['todo'],
    );
    if (file == null) return null;
    return PickedBackupFile(file.name, await file.readAsBytes());
  }

  @override
  Future<bool> save(String name, Uint8List bytes) async =>
      await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
        mimeType: 'application/octet-stream',
      ) !=
      null;
}

final backupFileGatewayProvider = Provider<BackupFileGateway>(
  (ref) => NativeBackupFileGateway(),
);
