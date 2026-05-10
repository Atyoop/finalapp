import 'package:flutter/material.dart';
import '../models/support_ticket.dart';
import '../services/support_service.dart';

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

  /// Submit a support request
  Future<bool> submitSupportRequest({
    required String token,
    required String category,
    required String message,
  }) async {
    _isSubmitting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await SupportService.submitSupportRequest(
        token: token,
        category: category,
        message: message,
      );

      _successMessage = 'Support request submitted successfully.';
      notifyListeners();

      // Fetch tickets again to update the list
      await fetchMyTickets(token);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ submitSupportRequest error: $e');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Fetch my support tickets
  Future<bool> fetchMyTickets(String token) async {
    _isFetching = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await SupportService.fetchMyTickets(token: token);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ fetchMyTickets error: $e');
      notifyListeners();
      return false;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Clear success message
  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

void debugPrint(String message) {
  print('[SupportProvider] $message');
}
