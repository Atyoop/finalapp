import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_schedule.dart';
import '../services/notification_service.dart';
import '../services/notification_schedule_service.dart';

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

  /// Fetch and schedule notifications
  Future<bool> fetchAndScheduleNotifications(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch schedules from backend
      _schedules = await NotificationScheduleService.fetchNotificationSchedules(
        token: token,
      );

      // Cancel all old notifications first
      await _notificationService.cancelAllNotifications();

      // Schedule new notifications for each pending schedule
      for (final schedule in _schedules) {
        if (schedule.status == 'Pending') {
          await _notificationService.scheduleNotifications(schedule);
        }
      }

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
  Future<void> testNotificationAfterDelay() async {
    try {
      await _notificationService.testNotificationAfterDelay(
        const Duration(seconds: 10),
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
}

void _debugPrint(String message) {
  debugPrint('[NotificationsProvider] $message');
}
