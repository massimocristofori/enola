import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialised = true;
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  Future<void> scheduleRiddleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'training_channel',
          'Training Reminders',
          channelDescription: 'Riddle training notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelNotification(int id) =>
      _plugin.cancel(id);

  Future<void> cancelAllNotifications() =>
      _plugin.cancelAll();

  // ── Pending ───────────────────────────────────────────────────────────────

  Future<List<PendingNotificationRequest>> getPendingNotifications() =>
      _plugin.pendingNotificationRequests();

  // ── Tap handler ───────────────────────────────────────────────────────────

  // Warm-start tap: app is in background/foreground.
  // Payload format: "mapId:riddleId"
  // TrainingService registers a listener here to handle navigation.
  void Function(String payload)? onNotificationTap;

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }
}
