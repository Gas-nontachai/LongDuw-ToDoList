import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../notifications/providers/daily_summary_controller.dart';
import '../models/backup_package.dart';
import '../services/backup_file_gateway.dart';
import '../services/backup_service.dart';

enum BackupStep {
  idle,
  summary,
  creating,
  saving,
  choosing,
  checking,
  preview,
  confirm,
  restoring,
  complete,
  cancelled,
  error,
}

enum BackupFlowError { backup, invalid, unsupported, restore }

class BackupController extends ChangeNotifier {
  BackupController({
    required this.service,
    required this.files,
    required this.appVersion,
    required this.notifications,
    required this.reloadApp,
    DateTime Function()? now,
    Future<ValidatedBackup> Function(Uint8List)? decodeBackup,
  }) : _now = now ?? DateTime.now,
       _decodeBackup = decodeBackup ?? _decodeInBackground;
  final BackupService service;
  final BackupFileGateway files;
  final Future<String> Function() appVersion;
  final DailySummaryController notifications;
  final Future<void> Function() reloadApp;
  final DateTime Function() _now;
  final Future<ValidatedBackup> Function(Uint8List) _decodeBackup;
  BackupStep step = BackupStep.idle;
  BackupFlowError? error;
  RestoreStage? restoreStage;
  int taskCount = 0;
  String fileName = '';
  ValidatedBackup? selected;
  bool isRestore = false;
  bool refreshFailed = false;
  bool _disposed = false;
  bool get busy => {
    BackupStep.creating,
    BackupStep.saving,
    BackupStep.choosing,
    BackupStep.checking,
    BackupStep.restoring,
  }.contains(step);

  void _set(BackupStep value) {
    step = value;
    if (!_disposed) notifyListeners();
  }

  Future<void> startBackup() async {
    if (step != BackupStep.idle) return;
    _set(BackupStep.creating);
    fileName = 'todo_backup_${DateFormat('yyyy-MM-dd').format(_now())}.todo';
    try {
      taskCount = await service.taskCount();
      _set(BackupStep.summary);
    } catch (_) {
      error = BackupFlowError.backup;
      _set(BackupStep.error);
    }
  }

  Future<void> createBackup() async {
    if (busy) return;
    _set(BackupStep.creating);
    try {
      final snapshot = await service.create(
        appVersion: await appVersion(),
        now: _now(),
      );
      taskCount = snapshot.backup.taskCount;
      _set(BackupStep.saving);
      final saved = await files.save(fileName, snapshot.bytes);
      _set(saved ? BackupStep.complete : BackupStep.cancelled);
    } catch (_) {
      error = BackupFlowError.backup;
      _set(BackupStep.error);
    }
  }

  Future<void> chooseBackup() async {
    if (busy) return;
    isRestore = true;
    selected = null;
    _set(BackupStep.choosing);
    try {
      final file = await files.pick();
      if (file == null) {
        _set(BackupStep.cancelled);
        return;
      }
      fileName = file.name;
      _set(BackupStep.checking);
      if (!file.name.toLowerCase().endsWith('.todo')) {
        throw const BackupException(BackupFailure.invalid);
      }
      selected = await _decodeBackup(file.bytes);
      taskCount = selected!.taskCount;
      _set(BackupStep.preview);
    } on BackupException catch (e) {
      error = e.failure == BackupFailure.unsupported
          ? BackupFlowError.unsupported
          : BackupFlowError.invalid;
      _set(BackupStep.error);
    } catch (_) {
      error = BackupFlowError.invalid;
      _set(BackupStep.error);
    }
  }

  static Future<ValidatedBackup> _decodeInBackground(Uint8List bytes) =>
      compute(_decode, bytes);

  static ValidatedBackup _decode(Uint8List bytes) =>
      const BackupCodec().decode(bytes);

  void confirm() {
    if (step == BackupStep.preview) _set(BackupStep.confirm);
  }

  void preview() {
    if (!busy && selected != null) _set(BackupStep.preview);
  }

  Future<void> restore() async {
    if (step != BackupStep.confirm || selected == null) return;
    _set(BackupStep.restoring);
    await notifications.pause();
    try {
      await service.restore(
        selected!,
        onStage: (stage) {
          restoreStage = stage;
          _set(BackupStep.restoring);
        },
      );
    } catch (_) {
      notifications.resume();
      error = BackupFlowError.restore;
      _set(BackupStep.error);
      return;
    }
    // The commit has succeeded. Subsequent UI/OS failures are never reported as
    // a rolled-back restore, and the imported data must not be undone.
    restoreStage = null;
    _set(BackupStep.restoring);
    await finishRestore();
  }

  Future<void> finishRestore() async {
    if (step == BackupStep.complete) _set(BackupStep.restoring);
    refreshFailed = false;
    try {
      await service.preferences.reload();
      await reloadApp();
    } catch (_) {
      refreshFailed = true;
    }
    notifications.resume();
    await notifications.refresh();
    if (step == BackupStep.restoring && selected != null) {
      _set(BackupStep.complete);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
