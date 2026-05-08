import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert.dart';

/// Service class for all Alerts API calls
class AlertsService {
  static const String _baseUrl = 'https://drugsafe.runasp.net/api';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
    'Authorization': 'Bearer $token',
  };

  /// GET /api/users/me/alerts — fetch all alerts
  static Future<List<Alert>> fetchAllAlerts(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/alerts'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      List<dynamic> list;

      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        list = decoded['data'] as List<dynamic>;
      } else if (decoded is Map && decoded.containsKey('\$values')) {
        list = decoded['\$values'] as List<dynamic>;
      } else {
        list = [];
      }

      return list
          .map((json) => Alert.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized', 401, response.body);
    } else {
      throw ApiException(
        'Failed to fetch alerts',
        response.statusCode,
        response.body,
      );
    }
  }

  /// GET /api/users/me/alerts/unread-count — fetch unread alerts count
  static Future<int> fetchUnreadCount(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/alerts/unread-count'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      // Handle both 'unreadCount' and 'UnreadCount' keys
      if (decoded is Map<String, dynamic>) {
        final count = decoded['unreadCount'] ?? decoded['UnreadCount'];
        if (count != null) {
          return (count as num).toInt();
        }
      }

      // If response is just an integer
      if (decoded is int) {
        return decoded;
      }

      return 0;
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized', 401, response.body);
    } else {
      throw ApiException(
        'Failed to fetch unread count',
        response.statusCode,
        response.body,
      );
    }
  }

  /// PATCH /api/alerts/{alertId}/read — mark one alert as read
  static Future<void> markAlertAsRead(String token, int alertId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/alerts/$alertId/read'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      if (response.statusCode == 401) {
        throw ApiException('Unauthorized', 401, response.body);
      }
      throw ApiException(
        'Failed to mark alert as read',
        response.statusCode,
        response.body,
      );
    }
  }

  /// PATCH /api/users/me/alerts/read-all — mark all alerts as read
  static Future<void> markAllAlertsAsRead(String token) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/users/me/alerts/read-all'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      if (response.statusCode == 401) {
        throw ApiException('Unauthorized', 401, response.body);
      }
      throw ApiException(
        'Failed to mark all alerts as read',
        response.statusCode,
        response.body,
      );
    }
  }

  /// DELETE /api/alerts/{alertId} — delete one alert
  static Future<void> deleteAlert(String token, int alertId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/alerts/$alertId'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      if (response.statusCode == 401) {
        throw ApiException('Unauthorized', 401, response.body);
      }
      throw ApiException(
        'Failed to delete alert',
        response.statusCode,
        response.body,
      );
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String body;

  ApiException(this.message, this.statusCode, this.body);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
