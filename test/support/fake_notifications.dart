import 'dart:async';

import 'package:longdow_todo_list/features/notifications/models/daily_summary.dart';
import 'package:longdow_todo_list/features/notifications/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class FakeNotifications implements NotificationService {
  @override
  bool supported = true;
  bool allowed = true;
  bool permissionGranted = true;
  int permissionRequests = 0;
  int initializations = 0;
  int? failAfter;
  Completer<void>? schedulingGate;
  Completer<bool>? permissionGate;
  final scheduled = <int, DailySummaryRequest>{};
  final bodies = <int, String>{};
  final titles = <int, String>{};
  final cancelled = <int>[];
  final extraIds = <int>[42];
  final previews = <({String title, String body})>[];
  bool failPreview = false;

  @override
  Future<void> showTest(String title, String body) async {
    if (failPreview) throw StateError('simulated preview failure');
    previews.add((title: title, body: body));
  }

  @override
  Future<void> initialize() async {
    initializations++;
  }

  @override
  Future<tz.Location> getLocation() async => tz.getLocation('Asia/Bangkok');
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    final granted = permissionGate == null
        ? allowed
        : await permissionGate!.future;
    permissionGranted = granted;
    return granted;
  }

  @override
  Future<bool> hasPermission() async => allowed && permissionGranted;
  @override
  Future<List<int>> pendingIds() async => [...extraIds, ...scheduled.keys];
  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
    bodies.remove(id);
    titles.remove(id);
  }

  @override
  Future<void> schedule(
    DailySummaryRequest request,
    String title,
    String body,
  ) async {
    await schedulingGate?.future;
    if (failAfter == scheduled.length) throw StateError('simulated OS failure');
    scheduled[request.id] = request;
    titles[request.id] = title;
    bodies[request.id] = body;
  }
}
