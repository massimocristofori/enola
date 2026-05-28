// lib/services/notification_service_web.dart

// We define a simple dummy class to prevent errors when other files 
// try to type-check against the return type of getPendingNotifications.
class PendingNotificationRequest {
  final int id = 0;
  final String? title = null;
  final String? body = null;
  final String? payload = null;
}

class NotificationService {
  // Singleton pattern must be preserved so your app logic doesn't break
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  static String lastPayload = 'web stub';

  // State management variables to prevent "not found" errors
  void Function(String payload)? onNotificationTap;

  // These methods are now empty (no-ops). 
  // Calling them on the web will do nothing, which is safe for debugging.
  Future<void> init() async {}

  void drainPendingLaunchNotification() {}

  Future<bool> requestPermissions() async => true;

  Future<void> scheduleRiddleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {}

  Future<void> cancelNotification(int id) async {}

  Future<void> cancelAllNotifications() async {}

  Future<List<PendingNotificationRequest>> getPendingNotifications() async => [];



}
