import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/daily_summary.dart';

abstract class NotificationService {
  bool get supported;
  Future<void> initialize();
  Future<tz.Location> getLocation();
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<List<int>> pendingIds();
  Future<void> cancel(int id);
  Future<void> schedule(DailySummaryRequest request, String title, String body);
  Future<void> showTest(String title, String body);
}

class LocalNotificationService implements NotificationService {
  static const testNotificationId = 9001;
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_summary',
      'Daily Summary',
      channelDescription: 'Daily overview of unfinished tasks',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_todo'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<tz.Location> getLocation() async =>
      tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier);

  @override
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()!
              .requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()!
            .requestPermissions(alert: true, sound: true, badge: false) ??
        false;
  }

  @override
  Future<bool> hasPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()!
              .areNotificationsEnabled() ??
          false;
    }
    return (await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()!
                .checkPermissions())
            ?.isEnabled ??
        false;
  }

  @override
  Future<List<int>> pendingIds() async =>
      (await _plugin.pendingNotificationRequests())
          .map((item) => item.id)
          .toList();

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> schedule(
    DailySummaryRequest request,
    String title,
    String body,
  ) => _plugin.zonedSchedule(
    id: request.id,
    title: title,
    body: body,
    scheduledDate: request.date,
    notificationDetails: _details,
    // Daily overviews do not need Android's special exact-alarm permission.
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: 'daily_summary',
  );

  @override
  Future<void> showTest(String title, String body) => _plugin.show(
    id: testNotificationId,
    title: title,
    body: body,
    notificationDetails: _details,
    payload: 'daily_summary_test',
  );
}
