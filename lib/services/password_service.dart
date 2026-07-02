import 'dart:convert';

import 'package:http/http.dart' as http;

class PasswordServiceException implements Exception {
  const PasswordServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PasswordService {
  static const String _baseUrl = 'https://drugsafe.runasp.net/api/Auth';
  static const Duration _timeout = Duration(seconds: 20);

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<void> requestResetOtp(String email) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/forgot-password'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(_timeout);
    _ensureSuccess(response);
  }

  static Future<String> verifyResetOtp(String email, String otp) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/verify-reset-otp'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email.trim(), 'otp': otp.trim()}),
        )
        .timeout(_timeout);
    final body = _ensureSuccess(response);
    final resetToken = body['resetToken']?.toString();
    if (resetToken == null || resetToken.isEmpty) {
      throw const PasswordServiceException('Reset token was not returned.');
    }
    return resetToken;
  }

  static Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/reset-password'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'email': email.trim(),
            'resetToken': resetToken,
            'newPassword': newPassword,
            'confirmPassword': confirmPassword,
          }),
        )
        .timeout(_timeout);
    _ensureSuccess(response);
  }

  static Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/change-password'),
          headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
          body: jsonEncode({
            'currentPassword': currentPassword,
            'newPassword': newPassword,
            'confirmPassword': confirmPassword,
          }),
        )
        .timeout(_timeout);
    _ensureSuccess(response);
  }

  static Map<String, dynamic> _ensureSuccess(http.Response response) {
    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    throw PasswordServiceException(
      body['message']?.toString() ?? 'Request failed.',
      statusCode: response.statusCode,
    );
  }
}
