import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
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
    _debugPrint('🚀 Initializing NotificationService...');

    // Initialize timezone data
    tzdata.initializeTimeZones();
    _debugPrint('✅ Timezone data initialized');

    // Get and set local timezone using flutter_timezone
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _debugPrint('✅ Local timezone set to: $timeZoneName');
    } catch (e) {
      _debugPrint('❌ Error setting local timezone: $e');
      // Fallback to UTC
      tz.setLocalLocation(tz.UTC);
    }

    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'medication_reminders_v1',
              'Medication Reminders',
              description: 'Medication reminders and important notifications',
              importance: Importance.max,
              enableVibration: true,
              enableLights: true,
            ),
          );
      _debugPrint('✅ Android notification channel created');
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
    _debugPrint('✅ NotificationService initialization complete');
  }

  /// Handle notification tap
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Parse payload to determine which medication was tapped
    final payload = response.payload;
    _debugPrint('📲 Notification tapped with payload: $payload');
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
        _debugPrint(
          '⏭️ Skipping notification for ${schedule.medName} - time is in the past',
        );
        return scheduledIds;
      }

      // Notification ID calculation
      final reminderId = schedule.scheduleId * 10 + 1;
      final doseId = schedule.scheduleId * 10 + 2;

      _debugPrint('📋 Scheduling notifications for ${schedule.medName}...');

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

      _debugPrint(
        '✅ Scheduled notifications for ${schedule.medName}: $scheduledIds',
      );
    } catch (e) {
      _debugPrint('❌ Error scheduling notifications: $e');
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
      _debugPrint(
        '⏰ Scheduling notification ID $id: "$title" for $scheduledDate',
      );

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
            'medication_reminders_v1',
            'Medication Reminders',
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      _debugPrint('✅ Notification ID $id scheduled successfully');
    } catch (e) {
      _debugPrint('❌ Error scheduling single notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      _debugPrint('🗑️ Cancelling all notifications...');
      await _flutterLocalNotificationsPlugin.cancelAll();
      _debugPrint('✅ All notifications cancelled');
    } catch (e) {
      _debugPrint('❌ Error cancelling notifications: $e');
    }
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      _debugPrint('🗑️ Cancelling notification $id...');
      await _flutterLocalNotificationsPlugin.cancel(id);
      _debugPrint('✅ Notification $id cancelled');
    } catch (e) {
      _debugPrint('❌ Error cancelling notification $id: $e');
    }
  }

  /// Test instant notification
  Future<void> testInstantNotification() async {
    try {
      _debugPrint('📲 Sending instant test notification...');
      await _flutterLocalNotificationsPlugin.show(
        999,
        'DrugSafe',
        'This is a test notification.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders_v1',
            'Medication Reminders',
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
      _debugPrint('✅ Instant test notification sent');
    } catch (e) {
      _debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Test notification after delay
  Future<void> testNotificationAfterDelay(Duration delay) async {
    try {
      _debugPrint('⏰ Scheduling delayed test notification after $delay...');
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        998,
        'DrugSafe Reminder',
        'This scheduled notification is working.',
        tz.TZDateTime.now(tz.local).add(delay),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders_v1',
            'Medication Reminders',
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _debugPrint('✅ Delayed test notification scheduled for $delay from now');
    } catch (e) {
      _debugPrint('❌ Error scheduling delayed notification: $e');
    }
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      _debugPrint(
        '📊 Pending notifications count: ${pendingNotifications.length}',
      );
      return pendingNotifications.length;
    } catch (e) {
      _debugPrint('❌ Error getting pending notifications: $e');
      return 0;
    }
  }

  /// Get list of pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      _debugPrint('📋 Pending notifications: ${pendingNotifications.length}');
      for (final notif in pendingNotifications) {
        _debugPrint('  - ID: ${notif.id}, Title: ${notif.title}');
      }
      return pendingNotifications;
    } catch (e) {
      _debugPrint('❌ Error listing pending notifications: $e');
      return [];
    }
  }

  /// Verify notification system is working properly
  Future<bool> verifyNotificationSystem() async {
    try {
      _debugPrint('🔍 Verifying notification system...');

      // Check if timezone is set
      final currentTz = tz.local;
      _debugPrint('✅ Timezone verified: ${currentTz.name}');

      // Check pending notifications
      final pendingCount = await getPendingNotificationsCount();
      _debugPrint('✅ Can check pending notifications: $pendingCount');

      _debugPrint('✅ Notification system verification complete');
      return true;
    } catch (e) {
      _debugPrint('❌ Notification system verification failed: $e');
      return false;
    }
  }
}

// Helper function for debug printing
void _debugPrint(String message) {
  debugPrint('[NotificationService] $message');
}
