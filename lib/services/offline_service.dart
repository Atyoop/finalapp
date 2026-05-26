import 'package:flutter/foundation.dart';
import 'hive_service.dart';

/// Service to manage offline/demo mode for testing without internet
class OfflineService {
  static const String _offlineUsersKey = 'offline_users';
  static const String _offlineModeKey = 'offline_mode_enabled';

  /// Enable demo mode - allows login without internet
  static Future<void> enableOfflineMode() async {
    try {
      await HiveService.settingsBox.put(_offlineModeKey, true);
      debugPrint('[OfflineService] ✅ Offline mode enabled');
    } catch (e) {
      debugPrint('[OfflineService] ❌ Error enabling offline mode: $e');
    }
  }

  /// Disable demo mode
  static Future<void> disableOfflineMode() async {
    try {
      await HiveService.settingsBox.delete(_offlineModeKey);
      debugPrint('[OfflineService] ✅ Offline mode disabled');
    } catch (e) {
      debugPrint('[OfflineService] ❌ Error disabling offline mode: $e');
    }
  }

  /// Check if offline mode is enabled
  static bool isOfflineModeEnabled() {
    try {
      return HiveService.settingsBox.get(_offlineModeKey, defaultValue: false)
          as bool;
    } catch (e) {
      debugPrint('[OfflineService] ❌ Error checking offline mode: $e');
      return false;
    }
  }

  /// Create or login with a demo account
  static Future<bool> loginWithDemo({
    required String email,
    required String password,
  }) async {
    try {
      // For demo: accept any email/password combination
      if (email.isEmpty || password.isEmpty) {
        return false;
      }

      // Generate a simple token based on email
      final demoToken =
          'demo_${email.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
      final demoUserId = 'demo_${email.hashCode}';

      // Store in Hive
      final usersBox = HiveService.authBox;
      await usersBox.put('demo_session', {
        'email': email,
        'token': demoToken,
        'userId': demoUserId,
        'isDemo': true,
        'loginTime': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('[OfflineService] ✅ Demo login successful: $email');
      return true;
    } catch (e) {
      debugPrint('[OfflineService] ❌ Error in demo login: $e');
      return false;
    }
  }

  /// Get demo session data
  static Map<String, dynamic>? getDemoSession() {
    try {
      final data = HiveService.authBox.get('demo_session');
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('[OfflineService] ❌ Error getting demo session: $e');
      return null;
    }
  }

  /// Check if a token is a demo/offline token
  static bool isDemoToken(String? token) {
    return token != null && token.startsWith('demo_');
  }

  /// Clear demo session
  static Future<void> clearDemoSession() async {
    try {
      await HiveService.authBox.delete('demo_session');
      debugPrint('[OfflineService] 🗑️ Demo session cleared');
    } catch (e) {
      debugPrint('[OfflineService] ❌ Error clearing demo session: $e');
    }
  }
}
