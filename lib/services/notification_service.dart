import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;
  NotificationResponse? _pendingLaunchResponse;

  // ── Temporary debug ───────────────────────────────────────────────────────
  static String lastPayload = 'never fired';

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

    // ── Cold-Start Check ─────────────────────────────────────────────────────
    // Store the response rather than firing it immediately.
    // TrainingService will drain this after all callbacks are wired in main.dart.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      _pendingLaunchResponse = launchDetails.notificationResponse;
    }

    _initialised = true;
  }

  // ── Drain pending cold-start notification ─────────────────────────────────
  // Call this after all tap-handler callbacks are fully wired.

  void drainPendingLaunchNotification() {
    final response = _pendingLaunchResponse;
    if (response != null) {
      _pendingLaunchResponse = null;
      _onNotificationTap(response);
    }
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelNotification(int id) => _plugin.cancel(id);

  Future<void> cancelAllNotifications() => _plugin.cancelAll();

  // ── Pending ───────────────────────────────────────────────────────────────

  Future<List<PendingNotificationRequest>> getPendingNotifications() =>
      _plugin.pendingNotificationRequests();

  // ── Tap handler ───────────────────────────────────────────────────────────

  void Function(String payload)? onNotificationTap;

  void _onNotificationTap(NotificationResponse response) {
    lastPayload =
        'payload: "${response.payload}", handler null: ${onNotificationTap == null}';
    final payload = response.payload;
    if (payload != null && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }
}
