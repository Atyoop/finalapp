import 'package:flutter/foundation.dart';
import 'hive_service.dart';

class AuthSession {
  final String token;
  final String userId;
  final int loginTimestamp;

  AuthSession({
    required this.token,
    required this.userId,
    required this.loginTimestamp,
  });

  Map<String, dynamic> toMap() => {
    'token': token,
    'userId': userId,
    'loginTimestamp': loginTimestamp,
  };

  factory AuthSession.fromMap(Map<String, dynamic> map) => AuthSession(
    token: map['token'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    loginTimestamp: map['loginTimestamp'] as int? ?? 0,
  );

  bool get isValid => token.isNotEmpty && userId.isNotEmpty;
}

class AuthStorageService {
  static const String _sessionKey = 'current_session';

  /// Save the current login session to Hive.
  static Future<void> saveSession({
    required String token,
    required String userId,
  }) async {
    try {
      final session = AuthSession(
        token: token,
        userId: userId,
        loginTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await HiveService.authBox.put(_sessionKey, session.toMap());
      debugPrint('[AuthStorage] ✅ Session saved');
    } catch (e) {
      debugPrint('[AuthStorage] ❌ Error saving session: $e');
    }
  }

  /// Restore the saved session from Hive. Returns null if no valid session.
  static AuthSession? restoreSession() {
    try {
      final data = HiveService.authBox.get(_sessionKey);
      if (data == null) return null;
      final session = AuthSession.fromMap(Map<String, dynamic>.from(data));
      if (!session.isValid) return null;
      return session;
    } catch (e) {
      debugPrint('[AuthStorage] ❌ Error restoring session: $e');
      return null;
    }
  }

  /// Check if a valid saved session exists.
  static bool hasSession() {
    final session = restoreSession();
    return session != null;
  }

  /// Clear the saved session (used during logout).
  static Future<void> clearSession() async {
    try {
      await HiveService.authBox.delete(_sessionKey);
      debugPrint('[AuthStorage] 🗑️ Session cleared');
    } catch (e) {
      debugPrint('[AuthStorage] ❌ Error clearing session: $e');
    }
  }
}
