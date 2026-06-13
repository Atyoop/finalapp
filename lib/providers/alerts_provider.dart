import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/alert.dart';
import '../services/alerts_service.dart';

class AlertsProvider extends ChangeNotifier {
  List<Alert> _alerts = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isMarkingAllRead = false;
  bool _isDeletingAll = false;
  String? _error;

  List<Alert> get alerts => _alerts;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isMarkingAllRead => _isMarkingAllRead;
  bool get isDeletingAll => _isDeletingAll;
  String? get error => _error;

  /// Safely notify listeners, deferring if called during build phase
  void _safeNotifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // We're in build phase, defer the notification until after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasListeners) return;
        notifyListeners();
      });
    } else {
      // Safe to notify immediately
      notifyListeners();
    }
  }

  /// Fetch all alerts
  Future<bool> fetchAlerts(String token) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final fetched = await AlertsService.fetchAllAlerts(token);
      fetched.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      _alerts = fetched;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ fetchAlerts error: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Fetch unread alerts count
  Future<bool> fetchUnreadCount(String token) async {
    try {
      _unreadCount = await AlertsService.fetchUnreadCount(token);
      _error = null;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ fetchUnreadCount error: $e');
      // Don't set isLoading for this, just notify silently
      _safeNotifyListeners();
      return false;
    }
  }

  /// Fetch unread alerts list
  Future<List<Alert>> fetchUnreadAlerts(String token) async {
    try {
      final unreadAlerts = await AlertsService.fetchUnreadAlerts(token);
      _error = null;
      return unreadAlerts;
    } catch (e) {
      _error = e.toString();
      debugPrint('âŒ fetchUnreadAlerts error: $e');
      _safeNotifyListeners();
      return [];
    }
  }

  /// Mark one alert as read
  Future<bool> markAlertAsRead(String token, int alertId) async {
    try {
      await AlertsService.markAlertAsRead(token, alertId);

      // Update local alert state
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = Alert(
          id: _alerts[index].id,
          title: _alerts[index].title,
          message: _alerts[index].message,
          type: _alerts[index].type,
          createdAt: _alerts[index].createdAt,
          isRead: true,
          scheduledAt: _alerts[index].scheduledAt,
          medicationName: _alerts[index].medicationName,
        );
      }

      // Refresh unread count
      await fetchUnreadCount(token);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ markAlertAsRead error: $e');
      _safeNotifyListeners();
      return false;
    }
  }

  /// Mark all alerts as read
  Future<bool> markAllAlertsAsRead(String token) async {
    _isMarkingAllRead = true;
    _safeNotifyListeners();

    try {
      await AlertsService.markAllAlertsAsRead(token);

      // Update all alerts to read
      for (int i = 0; i < _alerts.length; i++) {
        final alert = _alerts[i];
        _alerts[i] = Alert(
          id: alert.id,
          title: alert.title,
          message: alert.message,
          type: alert.type,
          createdAt: alert.createdAt,
          isRead: true,
          scheduledAt: alert.scheduledAt,
          medicationName: alert.medicationName,
        );
      }

      // Set unread count to 0
      _unreadCount = 0;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ markAllAlertsAsRead error: $e');
      return false;
    } finally {
      _isMarkingAllRead = false;
      _safeNotifyListeners();
    }
  }

  /// Delete one alert
  Future<bool> deleteAlert(String token, int alertId) async {
    try {
      await AlertsService.deleteAlert(token, alertId);

      // Remove from local list
      _alerts.removeWhere((a) => a.id == alertId);

      // Refresh unread count
      await fetchUnreadCount(token);
      _error = null;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ deleteAlert error: $e');
      _safeNotifyListeners();
      return false;
    }
  }

  /// Delete all alerts by deleting each one
  Future<bool> deleteAllAlerts(String token) async {
    _isDeletingAll = true;
    _safeNotifyListeners();

    try {
      // Delete each alert one by one
      final alertIds = _alerts.map((a) => a.id).toList();

      for (final alertId in alertIds) {
        try {
          await AlertsService.deleteAlert(token, alertId);
        } catch (e) {
          // Log but continue deleting others
          debugPrint('⚠️ Failed to delete alert $alertId: $e');
        }
      }

      // Clear local list
      _alerts.clear();

      // Refresh unread count
      _unreadCount = 0;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ deleteAllAlerts error: $e');
      return false;
    } finally {
      _isDeletingAll = false;
      _safeNotifyListeners();
    }
  }

  /// Refresh unread count (called after various actions)
  Future<void> refreshUnreadCount(String token) async {
    await fetchUnreadCount(token);
  }
}
