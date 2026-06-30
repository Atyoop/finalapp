import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/notification_schedule.dart';
import 'reminder_storage_service.dart';
import 'language_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _notificationIcon = 'ic_notification';
  static const String _channelId = 'medication_alarms_v4';
  static const String _channelName = 'Medication Reminders';
  static const String _channelDesc = 'Scheduled medication reminders';

  // MethodChannel for native Android calls (battery optimization)
  static const MethodChannel _androidChannel = MethodChannel(
    'com.example.final88/notifications',
  );

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

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(_notificationIcon);

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
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

    if (Platform.isAndroid) {
      await _createAlarmChannel();
      await _logAndroidNotificationState('initialize');
    }
    _debugPrint('✅ NotificationService initialization complete');
  }

  Future<void> requestReminderPermissions() async {
    if (Platform.isAndroid) {
      await _createAlarmChannel();
      await _requestAndroidPermissions();
      await _logAndroidNotificationState('manualPermissionSetup');
      await _requestBatteryOptimizationExemption();
      return;
    }

    if (Platform.isIOS) {
      try {
        final ios = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _debugPrint('iOS notification permission: $granted');
      } catch (error, stackTrace) {
        _logError('requesting iOS notification permissions', error, stackTrace);
      }
    }
  }

  Future<void> _createAlarmChannel() async {
    final android = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Clean up all old channel versions
    for (final oldId in [
      'medication_reminders_v1',
      'medication_alarms_v2',
      'medication_alarms_v3',
    ]) {
      try {
        await android?.deleteNotificationChannel(oldId);
        _debugPrint('🗑️ Deleted old channel: $oldId');
      } catch (_) {}
    }

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        // sound: null uses device default notification/alarm sound.
        // This is intentional — we do NOT override with a custom sound file
        // so the user's system alarm sound is used.
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
    } catch (error, stackTrace) {
      _logError(
        'requesting Android notification permissions',
        error,
        stackTrace,
      );
    }
  }

  Future<AndroidScheduleMode> _androidScheduleMode(String operation) async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final exactAlarmAllowed = await _logAndroidNotificationState(operation);
    if (exactAlarmAllowed) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final error = StateError(
      'Exact alarms are unavailable for $operation. Reinstall the latest APK '
      'so Android grants USE_EXACT_ALARM.',
    );
    _logError(operation, error, StackTrace.current);
    throw error;
  }

  Future<bool> _logAndroidNotificationState(String operation) async {
    if (!Platform.isAndroid) {
      return true;
    }

    bool notificationsEnabled = false;
    bool exactAlarmAllowed = false;
    bool ignoringBatteryOptimizations = false;

    try {
      final android = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      notificationsEnabled = await android?.areNotificationsEnabled() ?? false;
      exactAlarmAllowed =
          await android?.canScheduleExactNotifications() ?? false;
      ignoringBatteryOptimizations =
          await _androidChannel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;
    } catch (error, stackTrace) {
      _logError(
        'reading Android notification state for $operation',
        error,
        stackTrace,
      );
    }

    _debugPrint(
      '[$operation] permissions: notifications=$notificationsEnabled, '
      'exactAlarm=$exactAlarmAllowed, '
      'batteryOptimizationIgnored=$ignoringBatteryOptimizations',
    );

    return exactAlarmAllowed;
  }

  /// Ask the user to exempt this app from battery optimization.
  /// Without this, Doze mode suppresses exact alarms on most Android OEMs
  /// (Samsung, Xiaomi, Huawei, Oppo, Vivo, etc.).
  ///
  /// On Android 6+ this opens the system dialog:
  ///   "Allow app to run in background without restriction?"
  /// The user only sees this dialog once (the OS remembers the choice).
  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      // Use a MethodChannel to call the native Kotlin code that opens
      // ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS for this package.
      await _androidChannel.invokeMethod('requestBatteryOptimization');
      _debugPrint(
        '✅ Battery optimization exemption dialog shown (or already granted)',
      );
    } on PlatformException catch (error, stackTrace) {
      _logError('requesting battery optimization exemption', error, stackTrace);
    } catch (error, stackTrace) {
      _logError('requesting battery optimization exemption', error, stackTrace);
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
      final scheduleMode = await _androidScheduleMode('scheduleTestAlarm');
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        996,
        'DrugSafe notification test',
        'This notification was scheduled ${delay.inSeconds} seconds ago.',
        tz.TZDateTime.now(tz.local).add(delay),
        _alarmNotificationDetails(),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      await _logPendingNotificationCount('scheduleTestAlarm');
      _debugPrint('✅ Test alarm scheduled in ${delay.inSeconds}s');
    } catch (error, stackTrace) {
      _logError('scheduling test notification', error, stackTrace);
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
      final statusLower = schedule.status.toLowerCase();
      if (statusLower != 'pending' && statusLower != 'snoozed') {
        _debugPrint(
          '⏭️ Skipping ${schedule.medName} - status: ${schedule.status}',
        );
        return scheduledIds;
      }

      final now = DateTime.now();
      final localScheduledAt = schedule.scheduledAt.toLocal();
      final localNotificationTime = schedule.notificationTime.toLocal();

      final reminderId = schedule.scheduleId * 10 + 1;
      final doseId = schedule.scheduleId * 10 + 2;

      _debugPrint(
        '📋 Scheduling ${schedule.medName} (status: ${schedule.status})...',
      );

      final isAr = LanguageService.isArabic;
      if (statusLower == 'snoozed') {
        // For snoozed doses, only schedule the snooze alarm at notificationTime (SnoozedUntil) if in the future
        if (localNotificationTime.isAfter(now)) {
          final scheduled = await _scheduleAlarm(
            id: doseId,
            title: schedule.title.isNotEmpty
                ? schedule.title
                : (isAr ? '⏰ تذكير الغفوة' : '⏰ Snooze Reminder'),
            body: schedule.message.isNotEmpty
                ? schedule.message
                : (isAr
                      ? 'حان وقت تناول ${schedule.medName}'
                      : 'Time to take ${schedule.medName}'),
            scheduledDate: localNotificationTime,
            payload: 'dose_${schedule.scheduleId}',
          );
          if (scheduled) scheduledIds.add(doseId);
        } else {
          _debugPrint(
            '⏭️ Skipping snoozed ${schedule.medName} - snooze time is in the past',
          );
        }
      } else {
        // For normal pending doses:
        if (localScheduledAt.isBefore(now)) {
          _debugPrint(
            '⏭️ Skipping pending ${schedule.medName} - dose time in past',
          );
          return scheduledIds;
        }

        // 1. Schedule the advance reminder if it exists and is in the future
        if (localNotificationTime.isBefore(localScheduledAt)) {
          if (localNotificationTime.isAfter(now)) {
            final reminderScheduled = await _scheduleAlarm(
              id: reminderId,
              title: schedule.title.isNotEmpty
                  ? schedule.title
                  : (isAr ? '🔔 تذكير مسبق' : '🔔 Advance Reminder'),
              body: schedule.message.isNotEmpty
                  ? schedule.message
                  : (isAr
                        ? 'تذكير بدواء ${schedule.medName}'
                        : 'Reminder for ${schedule.medName}'),
              scheduledDate: localNotificationTime,
              payload: 'reminder_${schedule.scheduleId}',
            );
            if (reminderScheduled) scheduledIds.add(reminderId);
          } else {
            _debugPrint(
              '⏭️ Skipping advance reminder for ${schedule.medName} - time in past',
            );
          }

          // Since there is an advance reminder, the dose time alarm uses a default due title/body
          final dueTitle = isAr ? '🔔 تذكير الجرعة' : '🔔 Dose Reminder';
          final dueBody = isAr
              ? 'حان وقت تناول جرعتك من "${schedule.medName}"'
              : 'It\'s time to take your dose of "${schedule.medName}"';

          final doseScheduled = await _scheduleAlarm(
            id: doseId,
            title: dueTitle,
            body: dueBody,
            scheduledDate: localScheduledAt,
            payload: 'dose_${schedule.scheduleId}',
          );
          if (doseScheduled) scheduledIds.add(doseId);
        } else {
          // If no advance reminder (notificationTime == scheduledAt), schedule the single dose alarm with API text
          final scheduled = await _scheduleAlarm(
            id: doseId,
            title: schedule.title.isNotEmpty
                ? schedule.title
                : (isAr ? '⏰ حان وقت تناول الدواء' : '⏰ Dose Reminder Due Now'),
            body: schedule.message.isNotEmpty
                ? schedule.message
                : (isAr
                      ? 'حان وقت تناول جرعتك من ${schedule.medName}'
                      : 'It\'s time to take your dose of ${schedule.medName}'),
            scheduledDate: localScheduledAt,
            payload: 'dose_${schedule.scheduleId}',
          );
          if (scheduled) scheduledIds.add(doseId);
        }
      }

      _debugPrint('✅ Scheduled ${schedule.medName}: $scheduledIds');
    } catch (error, stackTrace) {
      _logError(
        'scheduling notifications for ${schedule.medName}',
        error,
        stackTrace,
      );
    }
    return scheduledIds;
  }

  // ───── Core scheduling (all goes through this) ─────

  Future<bool> _scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    try {
      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);
      final scheduleMode = await _androidScheduleMode(
        'scheduleAlarm(id=$id, payload=$payload)',
      );
      _debugPrint('⏰ Alarm ID $id: "$title" at $scheduledDate');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        _alarmNotificationDetails(),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      await _logPendingNotificationCount('scheduleAlarm(id=$id)');
      _debugPrint('✅ Alarm ID $id scheduled');
      return true;
    } catch (error, stackTrace) {
      _logError('scheduling alarm ID $id', error, stackTrace);
      return false;
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
      final scheduleMode = await _androidScheduleMode(
        'scheduleRepeatingReminder(id=$notifId)',
      );

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
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatIntervalHours >= 24
            ? DateTimeComponents.time
            : null,
        payload: medicineId,
      );

      await _logPendingNotificationCount(
        'scheduleRepeatingReminder(id=$notifId)',
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
    } catch (error, stackTrace) {
      _logError(
        'scheduling repeating reminder for $medicineName',
        error,
        stackTrace,
      );
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
      final scheduleMode = await _androidScheduleMode(
        'snoozeNotification(id=$notifId)',
      );

      _debugPrint('⏰ Snoozing $medicineName for $minutes min (ID: $notifId)');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notifId,
        '💤 Snoozed: $medicineName',
        '$dosage - Alarm in $minutes min',
        snoozeTime,
        _alarmNotificationDetails(),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: medicineId,
      );
      await _logPendingNotificationCount('snoozeNotification(id=$notifId)');

      _debugPrint('✅ $medicineName snoozed $minutes min');
      return true;
    } catch (error, stackTrace) {
      _logError('snoozing $medicineName', error, stackTrace);
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

  Future<void> cancelStaleBackendNotifications(Set<int> activeIds) async {
    try {
      final pending = await getPendingNotifications();
      final stale = pending.where((notification) {
        final payload = notification.payload ?? '';
        final isBackendNotification =
            payload.startsWith('dose_') || payload.startsWith('reminder_');
        return isBackendNotification && !activeIds.contains(notification.id);
      }).toList();

      for (final notification in stale) {
        await _flutterLocalNotificationsPlugin.cancel(notification.id);
      }

      _debugPrint(
        '[BackendReconcile] active=${activeIds.length}, '
        'cancelledStale=${stale.length}',
      );
    } catch (error, stackTrace) {
      _logError('cancelling stale backend notifications', error, stackTrace);
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

  Future<bool> testNotificationAfterDelay(Duration delay) async {
    final now = DateTime.now();
    final scheduledTime = now.add(delay);
    final notificationId = 998;

    final tzNow = tz.TZDateTime.now(tz.local);
    final tzScheduled = tzNow.add(delay);

    _debugPrint('=== [NotifTest] Scheduling delayed test notification ===');
    _debugPrint('[NotifTest] Device Local Time: $now');
    _debugPrint('[NotifTest] Device Scheduled Time: $scheduledTime');
    _debugPrint('[NotifTest] Local Timezone: ${tz.local.name}');
    _debugPrint('[NotifTest] tzNow (calculated): $tzNow');
    _debugPrint('[NotifTest] tzScheduled: $tzScheduled');
    _debugPrint('[NotifTest] now (millis): ${now.millisecondsSinceEpoch}');
    _debugPrint('[NotifTest] tzNow (millis): ${tzNow.millisecondsSinceEpoch}');
    _debugPrint(
      '[NotifTest] tzScheduled (millis): ${tzScheduled.millisecondsSinceEpoch}',
    );
    _debugPrint(
      '[NotifTest] Offset difference: ${tzNow.millisecondsSinceEpoch - now.millisecondsSinceEpoch} ms',
    );
    _debugPrint('[NotifTest] Notification ID: $notificationId');

    try {
      final scheduleMode = await _androidScheduleMode(
        'testNotificationAfterDelay',
      );
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'DrugSafe notification test',
        'This is the 30-second local notification test.',
        tzScheduled,
        _alarmNotificationDetails(),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _debugPrint('[NotifTest] zonedSchedule completed successfully');

      final count = await getPendingNotificationsCount();
      _debugPrint('[NotifTest] Pending notifications count: $count');
      _debugPrint('======================================================');
      return true;
    } catch (error, stackTrace) {
      _logError('running the delayed notification test', error, stackTrace);
      return false;
    }
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

  Future<void> _logPendingNotificationCount(String operation) async {
    final count = await getPendingNotificationsCount();
    _debugPrint('[$operation] Pending notification count: $count');
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
        icon: _notificationIcon,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        showWhen: true,
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

void _logError(String operation, Object error, StackTrace stackTrace) {
  debugPrint('[NotificationService] ERROR while $operation: $error');
  debugPrint('[NotificationService] STACK TRACE:\n$stackTrace');
}
