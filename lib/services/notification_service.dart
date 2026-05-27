import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

const String _kPendingPayloadKey = 'pending_notification_payload';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Temporary debug ───────────────────────────────────────────────────────
  static String lastPayload = 'never fired';

  // ── Called from top-level background handler in main.dart ────────────────
  // Runs on a background isolate — can only do synchronous or simple async
  // work. shared_preferences is safe here.
  static Future<void> setPendingBackground(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    lastPayload = 'background wrote: "$payload"';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingPayloadKey, payload);
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

    _initialised = true;
  }

  // ── Drain ─────────────────────────────────────────────────────────────────
  // Call this after all callbacks are wired. Checks both:
  //   1. shared_preferences (background isolate tap or cold start via background)
  //   2. getNotificationAppLaunchDetails (cold start via notification)

  Future<void> drainPendingLaunchNotification() async {
    // Check shared_preferences first (covers background tap → foreground)
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPendingPayloadKey);
    if (stored != null && stored.isNotEmpty) {
      await prefs.remove(_kPendingPayloadKey);
      lastPayload = 'drained from prefs: "$stored"';
      _firePayload(stored);
      return;
    }

    // Fallback: cold start via notification launch details
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        lastPayload = 'drained from launchDetails: "$payload"';
        _firePayload(payload);
        return;
      }
    }
  }

  void _firePayload(String payload) {
    if (onNotificationTap != null) {
      onNotificationTap!(payload);
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

  // ── Tap handler (foreground only) ─────────────────────────────────────────

  void Function(String payload)? onNotificationTap;

  void _onNotificationTap(NotificationResponse response) {
    lastPayload = 'foreground: "${response.payload}"';
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }
}
