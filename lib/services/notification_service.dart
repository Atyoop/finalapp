import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/notification_schedule.dart';
import 'reminder_storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'medication_alarms_v2';
  static const String _channelName = 'Medication Alarms';
  static const String _channelDesc = 'Alarm-style medication reminders';

  /// Complete initialization
  Future<void> initialize() async {
    _debugPrint('🚀 Initializing NotificationService...');

    tzdata.initializeTimeZones();
    _debugPrint('✅ Timezone data initialized');

    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _debugPrint('✅ Local timezone set to: $timeZoneName');
    } catch (e) {
      _debugPrint('❌ Error setting local timezone: $e');
      tz.setLocalLocation(tz.UTC);
    }

    if (Platform.isAndroid) {
      await _createAlarmChannel();
      await _requestAndroidPermissions();
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

  Future<void> _createAlarmChannel() async {
    final android = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Delete old channel first so we can recreate with new settings
    try {
      await android?.deleteNotificationChannel('medication_reminders_v1');
    } catch (_) {}

    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        sound: null,
      ),
    );
    _debugPrint('✅ Alarm channel created (ID: $_channelId)');
  }

  Future<void> _requestAndroidPermissions() async {
    try {
      final android = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return;

      // Request POST_NOTIFICATIONS (Android 13+)
      final granted = await android.requestNotificationsPermission();
      _debugPrint('📲 POST_NOTIFICATIONS permission: $granted');

      // Request exact alarm permission (Android 12+)
      final exactAlarm = await android.requestExactAlarmsPermission();
      _debugPrint('⏰ SCHEDULE_EXACT_ALARM permission: $exactAlarm');
    } catch (e) {
      _debugPrint('❌ Error requesting permissions: $e');
    }
  }

  /// Show a test alarm-style notification immediately (for debugging)
  Future<void> showTestAlarmNow() async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        997,
        '🔔 DrugSafe Alarm Test',
        'If you see this, alarm notifications are working!',
        _alarmNotificationDetails(),
      );
      _debugPrint('✅ Test alarm shown immediately');
    } catch (e) {
      _debugPrint('❌ Error showing test alarm: $e');
    }
  }

  /// Schedule a test alarm after a delay
  Future<void> scheduleTestAlarm(Duration delay) async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        996,
        '🔔 DrugSafe Scheduled Test',
        'This alarm was scheduled ${delay.inSeconds}s ago',
        tz.TZDateTime.now(tz.local).add(delay),
        _alarmNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _debugPrint('✅ Test alarm scheduled in ${delay.inSeconds}s');
    } catch (e) {
      _debugPrint('❌ Error scheduling test alarm: $e');
    }
  }

  /// Called when user taps the notification
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    _debugPrint(
      '📲 Notification tapped - payload: $payload, actionId: ${response.actionId}',
    );
  }

  // ───── Schedule backend notifications (original flow) ─────

  Future<List<int>> scheduleNotifications(NotificationSchedule schedule) async {
    final scheduledIds = <int>[];
    try {
      if (schedule.status != 'Pending') {
        _debugPrint(
          '⏭️ Skipping ${schedule.medName} - status: ${schedule.status}',
        );
        return scheduledIds;
      }

      final now = DateTime.now();
      final localScheduledAt = schedule.scheduledAt.toLocal();
      final localNotificationTime = schedule.notificationTime.toLocal();

      if (localScheduledAt.isBefore(now) ||
          localNotificationTime.isBefore(now)) {
        _debugPrint('⏭️ Skipping ${schedule.medName} - time in past');
        return scheduledIds;
      }

      final reminderId = schedule.scheduleId * 10 + 1;
      final doseId = schedule.scheduleId * 10 + 2;

      _debugPrint('📋 Scheduling ${schedule.medName}...');

      await _scheduleAlarm(
        id: reminderId,
        title: '🔔 Medication Reminder',
        body: '${schedule.medName} in 15 minutes',
        scheduledDate: localNotificationTime,
        payload: 'reminder_${schedule.scheduleId}',
      );
      scheduledIds.add(reminderId);

      await _scheduleAlarm(
        id: doseId,
        title: '⏰ Time to take your medicine',
        body: 'Time to take ${schedule.medName}',
        scheduledDate: localScheduledAt,
        payload: 'dose_${schedule.scheduleId}',
      );
      scheduledIds.add(doseId);

      _debugPrint('✅ Scheduled ${schedule.medName}: $scheduledIds');
    } catch (e) {
      _debugPrint('❌ Error scheduling: $e');
    }
    return scheduledIds;
  }

  // ───── Core scheduling (all goes through this) ─────

  Future<void> _scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    try {
      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);
      _debugPrint('⏰ Alarm ID $id: "$title" at $scheduledDate');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        _alarmNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      _debugPrint('✅ Alarm ID $id scheduled');
    } catch (e) {
      _debugPrint('❌ Error scheduling alarm ID $id: $e');
    }
  }

  Future<bool> scheduleRepeatingReminder({
    required String medicineId,
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
    int repeatIntervalHours = 24,
  }) async {
    try {
      final notifId = getNotificationIdForMedicine(medicineId);
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      _debugPrint(
        '⏰ Repeating alarm for $medicineName at '
        '${_formatTime(hour, minute)} every ${repeatIntervalHours}h (ID: $notifId)',
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notifId,
        '⏰ $medicineName',
        '$dosage - ${_formatTime(hour, minute)}',
        tzScheduled,
        _alarmNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatIntervalHours >= 24
            ? DateTimeComponents.time
            : null,
        payload: medicineId,
      );

      await ReminderStorageService.saveReminder(
        LocalReminder(
          medicineId: medicineId,
          medicineName: medicineName,
          dosage: dosage,
          hour: hour,
          minute: minute,
          repeatIntervalHours: repeatIntervalHours,
          isActive: true,
        ),
      );

      _debugPrint('✅ Repeating alarm for $medicineName');
      return true;
    } catch (e) {
      _debugPrint('❌ Error scheduling repeating: $e');
      return false;
    }
  }

  // ───── Action helpers ─────

  int getNotificationIdForMedicine(String medicineId) {
    return medicineId.hashCode.abs();
  }

  Future<bool> snoozeNotification({
    required String medicineId,
    required String medicineName,
    required String dosage,
    int minutes = 5,
  }) async {
    try {
      final notifId = getNotificationIdForMedicine(medicineId);
      await cancelNotification(notifId);

      final snoozeTime = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(minutes: minutes));

      _debugPrint('⏰ Snoozing $medicineName for $minutes min (ID: $notifId)');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notifId,
        '💤 Snoozed: $medicineName',
        '$dosage - Alarm in $minutes min',
        snoozeTime,
        _alarmNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: medicineId,
      );

      _debugPrint('✅ $medicineName snoozed $minutes min');
      return true;
    } catch (e) {
      _debugPrint('❌ Error snoozing: $e');
      return false;
    }
  }

  Future<bool> markAsTaken({
    required String medicineId,
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
    int repeatIntervalHours = 24,
  }) async {
    try {
      final notifId = getNotificationIdForMedicine(medicineId);
      await cancelNotification(notifId);
      _debugPrint('✅ $medicineName taken (notification $notifId cancelled)');

      if (repeatIntervalHours >= 24) {
        await scheduleRepeatingReminder(
          medicineId: medicineId,
          medicineName: medicineName,
          dosage: dosage,
          hour: hour,
          minute: minute,
          repeatIntervalHours: repeatIntervalHours,
        );
        _debugPrint('🔄 $medicineName rescheduled for tomorrow');
      }
      return true;
    } catch (e) {
      _debugPrint('❌ Error marking taken: $e');
      return false;
    }
  }

  Future<int> rescheduleAllAfterBoot() async {
    try {
      _debugPrint('🔄 Rescheduling after boot...');
      final reminders = await ReminderStorageService.getReminders();
      int count = 0;
      for (final r in reminders) {
        if (!r.isActive) continue;
        final ok = await scheduleRepeatingReminder(
          medicineId: r.medicineId,
          medicineName: r.medicineName,
          dosage: r.dosage,
          hour: r.hour,
          minute: r.minute,
          repeatIntervalHours: r.repeatIntervalHours,
        );
        if (ok) count++;
      }
      _debugPrint('✅ Rescheduled $count/${reminders.length} after boot');
      return count;
    } catch (e) {
      _debugPrint('❌ Error rescheduling after boot: $e');
      return 0;
    }
  }

  // ───── Cancel helpers ─────

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _debugPrint('🗑️ All notifications cancelled');
    } catch (e) {
      _debugPrint('❌ Error cancelling all: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      _debugPrint('🗑️ Cancelled notification $id');
    } catch (e) {
      _debugPrint('❌ Error cancelling $id: $e');
    }
  }

  // ───── Testing & debug ─────

  Future<void> testInstantNotification() async {
    await _flutterLocalNotificationsPlugin.show(
      999,
      '💊 DrugSafe',
      'Instant test notification',
      _alarmNotificationDetails(),
    );
  }

  Future<void> testNotificationAfterDelay(Duration delay) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      998,
      '💊 DrugSafe Reminder',
      'Scheduled notification test',
      tz.TZDateTime.now(tz.local).add(delay),
      _alarmNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<int> getPendingNotificationsCount() async {
    try {
      final list = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (_) {
      return [];
    }
  }

  Future<bool> verifyNotificationSystem() async {
    try {
      _debugPrint('🔍 Verifying...');
      _debugPrint('✅ Timezone: ${tz.local.name}');
      final count = await getPendingNotificationsCount();
      _debugPrint('✅ Pending: $count');
      return true;
    } catch (e) {
      _debugPrint('❌ Verify failed: $e');
      return false;
    }
  }

  // ───── Notification details ─────

  NotificationDetails _alarmNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        showWhen: true,
        usesChronometer: true,
        sound: null, // uses default system alarm sound
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }
}

void _debugPrint(String message) {
  debugPrint('[NotificationService] $message');
}
