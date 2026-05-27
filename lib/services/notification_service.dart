import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// Forward declaration — main.dart defines the actual top-level function
// and passes it to init(). Stored here so the background isolate can
// write to a shared static slot.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // Holds a response that arrived while the app was backgrounded or
  // cold-started via notification tap.
  static NotificationResponse? _pendingResponse;

  // ── Temporary debug ───────────────────────────────────────────────────────
  static String lastPayload = 'never fired';

  // Called from the top-level background handler in main.dart
  static void setPendingBackground(NotificationResponse response) {
    _pendingResponse = response;
    lastPayload = 'background set: "${response.payload}"';
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init({
    void Function(NotificationResponse)? onBackground,
  }) async {
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
      onDidReceiveBackgroundNotificationResponse: onBackground,
    );

    // ── Cold-Start Check ─────────────────────────────────────────────────────
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final response = launchDetails.notificationResponse;
      if (response != null) {
        _pendingResponse = response;
        lastPayload = 'cold-start set: "${response.payload}"';
      }
    }

    _initialised = true;
  }

  // ── Drain ─────────────────────────────────────────────────────────────────

  void drainPendingLaunchNotification() {
    final response = _pendingResponse;
    if (response != null) {
      _pendingResponse = null;
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
    lastPayload = 'payload: "${response.payload}", handler null: ${onNotificationTap == null}';
    final payload = response.payload;
    if (payload != null && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }
}
