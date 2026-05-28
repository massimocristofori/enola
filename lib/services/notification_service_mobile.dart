import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // Buffers a tap that arrived before onNotificationTap was wired
  String? _bufferedPayload;

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
      // No background handler — we handle everything in the main isolate
    );

    // Cold start: app was launched by tapping a notification
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        lastPayload = 'cold-start buffered: "$payload"';
        _bufferedPayload = payload;
      }
    }

    _initialised = true;
  }

  // ── Wire the tap callback ─────────────────────────────────────────────────
  // Call this after setting onNotificationTap to flush any buffered payload.

  void Function(String payload)? _onNotificationTap_handler;

  void Function(String payload)? get onNotificationTap =>
      _onNotificationTap_handler;

  set onNotificationTap(void Function(String payload)? handler) {
    _onNotificationTap_handler = handler;
    // Flush any payload that arrived before the handler was ready
    if (handler != null && _bufferedPayload != null) {
      final payload = _bufferedPayload!;
      _bufferedPayload = null;
      lastPayload = 'flushed buffer: "$payload"';
      Future.microtask(() => handler(payload));
    }
  }

  // ── Drain (call after runApp for belt-and-suspenders) ─────────────────────

  void drainPendingLaunchNotification() {
    final payload = _bufferedPayload;
    if (payload != null && _onNotificationTap_handler != null) {
      _bufferedPayload = null;
      lastPayload = 'drained: "$payload"';
      _onNotificationTap_handler!(payload);
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

  // ── Internal tap handler ──────────────────────────────────────────────────

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    lastPayload = 'received: "$payload", handler null: ${_onNotificationTap_handler == null}';
    if (_onNotificationTap_handler != null) {
      _onNotificationTap_handler!(payload);
    } else {
      // Handler not wired yet — buffer it
      _bufferedPayload = payload;
    }
  }
}
