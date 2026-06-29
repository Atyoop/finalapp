import 'package:flutter/foundation.dart';
import '../models/notification_schedule.dart';
import '../services/notification_service.dart';
import '../services/notification_schedule_service.dart';
import '../services/reminder_storage_service.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationSchedule> _schedules = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  List<NotificationSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  Future<void> requestReminderPermissions() async {
    try {
      await _notificationService.requestReminderPermissions();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error requesting reminder permissions: $e');
      notifyListeners();
    }
  }

  /// Fetch and schedule notifications
  Future<bool> fetchAndScheduleNotifications(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedSchedules =
          await NotificationScheduleService.fetchNotificationSchedules(
            token: token,
          );

      final activeBackendIds = <int>{};
      for (final schedule in fetchedSchedules) {
        final statusLower = schedule.status.toLowerCase();
        if (statusLower == 'pending' || statusLower == 'snoozed') {
          activeBackendIds.addAll(
            await _notificationService.scheduleNotifications(schedule),
          );
        }
      }

      // Scheduling the same IDs updates existing alarms in place. Only remove
      // backend alarms that are no longer active; test and local alarms must
      // survive background refreshes.
      await _notificationService.cancelStaleBackendNotifications(
        activeBackendIds,
      );
      _schedules = fetchedSchedules;

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ fetchAndScheduleNotifications error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh notifications (call this after Take, Snooze, Skip actions)
  Future<bool> refreshNotifications(String token) async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await fetchAndScheduleNotifications(token);
      _isRefreshing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isRefreshing = false;
      notifyListeners();
      return false;
    }
  }

  /// Test instant notification
  Future<void> testInstantNotification() async {
    try {
      await _notificationService.testInstantNotification();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Test notification after delay
  Future<bool> testNotificationAfterDelay() async {
    try {
      final scheduled = await _notificationService.testNotificationAfterDelay(
        const Duration(seconds: 30),
      );
      if (!scheduled) {
        _error = 'The Android system rejected the scheduled notification.';
        notifyListeners();
      }
      return scheduled;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    return await _notificationService.getPendingNotificationsCount();
  }

  /// Verify notification system is working
  Future<bool> verifyNotificationSystem() async {
    try {
      return await _notificationService.verifyNotificationSystem();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get pending notifications (for debugging)
  Future<void> checkPendingNotifications() async {
    try {
      await _notificationService.getPendingNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Show test alarm immediately (new alarm-style)
  Future<void> showTestAlarmNow() async {
    await _notificationService.showTestAlarmNow();
  }

  /// Schedule a test alarm after a delay
  Future<void> scheduleTestAlarm(int seconds) async {
    await _notificationService.scheduleTestAlarm(Duration(seconds: seconds));
  }

  // ───── Local Reminder Methods ─────

  /// Schedule a repeating local reminder
  Future<bool> scheduleRepeatingReminder({
    required String medicineId,
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
    int repeatIntervalHours = 24,
  }) async {
    return await _notificationService.scheduleRepeatingReminder(
      medicineId: medicineId,
      medicineName: medicineName,
      dosage: dosage,
      hour: hour,
      minute: minute,
      repeatIntervalHours: repeatIntervalHours,
    );
  }

  /// Snooze a medicine reminder
  Future<bool> snoozeNotification({
    required String medicineId,
    required String medicineName,
    required String dosage,
    int minutes = 5,
  }) async {
    return await _notificationService.snoozeNotification(
      medicineId: medicineId,
      medicineName: medicineName,
      dosage: dosage,
      minutes: minutes,
    );
  }

  /// Mark medicine as taken
  Future<bool> markAsTaken({
    required String medicineId,
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
    int repeatIntervalHours = 24,
  }) async {
    return await _notificationService.markAsTaken(
      medicineId: medicineId,
      medicineName: medicineName,
      dosage: dosage,
      hour: hour,
      minute: minute,
      repeatIntervalHours: repeatIntervalHours,
    );
  }

  /// Reschedule all reminders from local storage (call after boot)
  Future<int> rescheduleAllAfterBoot() async {
    return await _notificationService.rescheduleAllAfterBoot();
  }

  /// Cancel a specific medicine notification by ID
  Future<void> cancelMedicineNotification(String medicineId) async {
    final notifId = _notificationService.getNotificationIdForMedicine(
      medicineId,
    );
    await _notificationService.cancelNotification(notifId);
  }

  Future<void> cancelBackendNotificationsForUserMedication(
    int userMedicationId,
  ) async {
    final schedulesToCancel = _schedules.where(
      (schedule) => schedule.userMedId == userMedicationId,
    );
    for (final schedule in schedulesToCancel) {
      await _notificationService.cancelNotification(
        schedule.scheduleId * 10 + 1,
      );
      await _notificationService.cancelNotification(
        schedule.scheduleId * 10 + 2,
      );
    }
    _schedules = _schedules
        .where((schedule) => schedule.userMedId != userMedicationId)
        .toList();
    notifyListeners();
  }

  /// Get all local reminders from storage
  Future<List<LocalReminder>> getLocalReminders() async {
    return await ReminderStorageService.getReminders();
  }

  /// Save a local reminder
  Future<bool> saveLocalReminder(LocalReminder reminder) async {
    return await ReminderStorageService.saveReminder(reminder);
  }

  /// Delete a local reminder
  Future<bool> deleteLocalReminder(String medicineId) async {
    final cancelled = _notificationService.getNotificationIdForMedicine(
      medicineId,
    );
    await _notificationService.cancelNotification(cancelled);
    return await ReminderStorageService.deleteReminder(medicineId);
  }

  /// Toggle a local reminder on/off
  Future<bool> toggleLocalReminder(String medicineId, bool isActive) async {
    if (isActive) {
      final reminders = await ReminderStorageService.getReminders();
      final reminder = reminders
          .where((r) => r.medicineId == medicineId)
          .firstOrNull;
      if (reminder != null) {
        await _notificationService.scheduleRepeatingReminder(
          medicineId: reminder.medicineId,
          medicineName: reminder.medicineName,
          dosage: reminder.dosage,
          hour: reminder.hour,
          minute: reminder.minute,
          repeatIntervalHours: reminder.repeatIntervalHours,
        );
      }
    } else {
      final notifId = _notificationService.getNotificationIdForMedicine(
        medicineId,
      );
      await _notificationService.cancelNotification(notifId);
    }
    return await ReminderStorageService.toggleReminder(medicineId, isActive);
  }

  Future<void> clearAll() async {
    _schedules.clear();
    await _notificationService.cancelAllNotifications();
    notifyListeners();
  }
}
