import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_profile.dart';

class UserProfileException implements Exception {
  final String message;

  const UserProfileException(this.message);

  @override
  String toString() => message;
}

class UserProfileService {
  static const _url = 'https://drugsafe.runasp.net/api/Users/me';

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<UserProfile> getProfile(String token) async {
    final response = await http
        .get(Uri.parse(_url), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    return _parseProfile(response);
  }

  static Future<UserProfile> updateProfile(
    String token, {
    required String fullName,
    required String phoneNumber,
    required DateTime? dateOfBirth,
    required String gender,
  }) async {
    final response = await http
        .put(
          Uri.parse(_url),
          headers: _headers(token),
          body: jsonEncode({
            'fullName': fullName,
            'phoneNumber': phoneNumber,
            'dateOfBirth': dateOfBirth?.toIso8601String(),
            'gender': gender,
          }),
        )
        .timeout(const Duration(seconds: 20));
    return _parseProfile(response);
  }

  static UserProfile _parseProfile(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300 && body != null) {
      return UserProfile.fromJson(body);
    }

    throw UserProfileException(
      body?['message']?.toString() ?? 'Could not update profile.',
    );
  }
}
