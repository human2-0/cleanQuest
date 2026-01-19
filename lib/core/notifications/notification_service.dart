import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/data/notification_log_repository.dart';
import '../../features/notifications/domain/notification_log_entry.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();
  static const int _dailyDigestId = 92001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  NotificationLogRepository? _logRepository;

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  Future<bool> requestPermissions() async {
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final macos = await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return (ios ?? true) && (macos ?? true) && (android ?? true);
  }

  void attachLogRepository(NotificationLogRepository repository) {
    _logRepository = repository;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) {
    const androidDetails = AndroidNotificationDetails(
      'cleanquest_alerts',
      'CleanQuest Alerts',
      channelDescription: 'Approvals and rewards notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    _logRepository?.addLog(
      NotificationLogEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
    return _plugin.show(id, title, body, details);
  }

  Future<void> scheduleDailyDigest({
    required String title,
    required String body,
  }) {
    const androidDetails = AndroidNotificationDetails(
      'cleanquest_digest',
      'CleanQuest Digest',
      channelDescription: 'Daily summary of due and overdue items',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    return _plugin.periodicallyShow(
      _dailyDigestId,
      title,
      body,
      RepeatInterval.daily,
      details,
      androidAllowWhileIdle: true,
    );
  }

  Future<void> cancelDailyDigest() {
    return _plugin.cancel(_dailyDigestId);
  }
}
