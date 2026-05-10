import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/premium_status.dart';
import '../services/premium_service.dart';

class PremiumProvider extends ChangeNotifier {
  PremiumStatus? _status;
  bool _isLoading = false;
  bool _isActivating = false;
  bool _isCancelling = false;
  String? _error;
  String? _successMessage;

  PremiumStatus? get status => _status;
  bool get isLoading => _isLoading;
  bool get isActivating => _isActivating;
  bool get isCancelling => _isCancelling;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get isPremiumActive => _status?.isActive ?? false;
  int get remainingDays => _status?.remainingDays ?? 0;

  /// Fetch premium status
  Future<bool> fetchPremiumStatus(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _status = await PremiumService.getPremiumStatus(token: token);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ fetchPremiumStatus error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Activate premium plan
  Future<bool> activatePremium({
    required String token,
    required String plan, // "Month", "ThreeMonths", "Year"
  }) async {
    _isActivating = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await PremiumService.activatePremium(token: token, plan: plan);

      _successMessage =
          'Payment completed successfully.\nYou are now a Premium user.';
      notifyListeners();

      // Fetch updated status
      await fetchPremiumStatus(token);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ activatePremium error: $e');
      notifyListeners();
      return false;
    } finally {
      _isActivating = false;
      notifyListeners();
    }
  }

  /// Cancel premium subscription
  Future<bool> cancelPremium(String token) async {
    _isCancelling = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await PremiumService.cancelPremium(token: token);

      _successMessage = 'Your Premium subscription has been cancelled.';
      notifyListeners();

      // Fetch updated status
      await fetchPremiumStatus(token);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ cancelPremium error: $e');
      notifyListeners();
      return false;
    } finally {
      _isCancelling = false;
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

void _debugPrint(String message) {
  debugPrint('[PremiumProvider] $message');
}
