import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Returns true if the device has an active internet connection.
  static Future<bool> hasInternet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('[Connectivity] Error checking: $e');
      return false;
    }
  }
}
