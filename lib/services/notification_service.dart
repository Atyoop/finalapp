import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:io' show Platform;
import '../models/notification_schedule.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone
    tzdata.initializeTimeZones();

    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'high_importance_channel',
              'High Importance Notifications',
              description: 'Medication reminders and important notifications',
              importance: Importance.max,
              enableVibration: true,
              enableLights: true,
            ),
          );
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  /// Handle notification tap
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Parse payload to determine which medication was tapped
    final payload = response.payload;
    debugPrint('📲 Notification tapped with payload: $payload');
    // This will be handled by calling code
  }

  /// Schedule medication notifications
  /// Returns the notification IDs that were scheduled
  Future<List<int>> scheduleNotifications(NotificationSchedule schedule) async {
    final scheduledIds = <int>[];

    try {
      // Only schedule if status is Pending and time is in the future
      if (schedule.status != 'Pending') {
        _debugPrint(
          '⏭️ Skipping notification for ${schedule.medName} - status is ${schedule.status}',
        );
        return scheduledIds;
      }

      final now = DateTime.now();
      final localScheduledAt = schedule.scheduledAt.toLocal();
      final localNotificationTime = schedule.notificationTime.toLocal();

      // Skip if times are in the past
      if (localScheduledAt.isBefore(now) ||
          localNotificationTime.isBefore(now)) {
        debugPrint(
          '⏭️ Skipping notification for ${schedule.medName} - time is in the past',
        );
        return scheduledIds;
      }

      // Notification ID calculation
      final reminderId = schedule.scheduleId * 10 + 1;
      final doseId = schedule.scheduleId * 10 + 2;

      // 1. Schedule reminder notification
      await _scheduleNotification(
        id: reminderId,
        title: 'Medication Reminder',
        body: '${schedule.medName} in 15 minutes',
        scheduledDate: localNotificationTime,
        payload: 'reminder_${schedule.scheduleId}',
      );
      scheduledIds.add(reminderId);

      // 2. Schedule dose notification
      await _scheduleNotification(
        id: doseId,
        title: 'Time to take your medicine',
        body: 'Time to take ${schedule.medName}',
        scheduledDate: localScheduledAt,
        payload: 'dose_${schedule.scheduleId}',
      );
      scheduledIds.add(doseId);

      debugPrint(
        '✅ Scheduled notifications for ${schedule.medName}: $scheduledIds',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling notifications: $e');
    }

    return scheduledIds;
  }

  /// Internal helper to schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    try {
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Medication reminders',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            enableLights: true,
            sound: const RawResourceAndroidNotificationSound(
              'notification_sound',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            sound: 'notification_sound.wav',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Error scheduling single notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling notifications: $e');
    }
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('✅ Notification $id cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling notification $id: $e');
    }
  }

  /// Test instant notification
  Future<void> testInstantNotification() async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        999,
        'Test Notification',
        'This is a test notification from DrugSafe',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Test notification',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('✅ Test notification sent');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Test notification after delay
  Future<void> testNotificationAfterDelay(Duration delay) async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        998,
        'Delayed Test Notification',
        'This notification was delayed',
        tz.TZDateTime.now(tz.local).add(delay),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Delayed test notification',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('✅ Delayed test notification scheduled');
    } catch (e) {
      debugPrint('❌ Error scheduling delayed notification: $e');
    }
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      return pendingNotifications.length;
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return 0;
    }
  }
}

// Helper function for debug printing
void _debugPrint(String message) {
  debugPrint('[NotificationService] $message');
}
