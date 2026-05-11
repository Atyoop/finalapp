import 'package:flutter/material.dart';
import '../models/support_ticket.dart';
import '../services/support_service.dart';
import 'package:flutter/scheduler.dart';

class SupportProvider extends ChangeNotifier {
  List<SupportTicket> _tickets = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isFetching = false;
  String? _error;
  String? _successMessage;

  List<SupportTicket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isFetching => _isFetching;
  String? get error => _error;
  String? get successMessage => _successMessage;

  bool _isNotificationPending = false;

  /// Safely notify listeners, deferring if called during build phase
  void _safeNotifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (!_isNotificationPending) {
        _isNotificationPending = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _isNotificationPending = false;
          if (hasListeners) notifyListeners();
        });
      }
    } else {
      notifyListeners();
    }
  }

  /// Submit a support request
  Future<bool> submitSupportRequest({
    required String token,
    required String category,
    required String message,
  }) async {
    _isSubmitting = true;
    _error = null;
    _successMessage = null;
    _safeNotifyListeners();

    try {
      await SupportService.submitSupportRequest(
        token: token,
        category: category,
        message: message,
      );

      _successMessage = 'Support request submitted successfully.';
      _safeNotifyListeners();

      // Fetch tickets again to update the list
      await fetchMyTickets(token);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ submitSupportRequest error: $e');
      _safeNotifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      _safeNotifyListeners();
    }
  }

  /// Fetch my support tickets
  Future<bool> fetchMyTickets(String token) async {
    _isFetching = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _tickets = await SupportService.fetchMyTickets(token: token);
      _error = null;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ fetchMyTickets error: $e');
      _safeNotifyListeners();
      return false;
    } finally {
      _isFetching = false;
      _safeNotifyListeners();
    }
  }

  /// Clear success message
  void clearSuccessMessage() {
    _successMessage = null;
    _safeNotifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }
}

void debugPrint(String message) {
  print('[SupportProvider] $message');
}
