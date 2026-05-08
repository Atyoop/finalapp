import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine.dart';

/// Service class for all UserMedications API calls
class UserMedicationsService {
  static const String _baseUrl =
      'https://drugsafe.runasp.net/api/UserMedications';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
    'Authorization': 'Bearer $token',
  };

  /// GET /api/UserMedications/myusermeds — fetch all user medications
  static Future<List<Medicine>> fetchAll(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/myusermeds'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      try {
        // Helpful debug information when names are missing in UI
        if (decoded is List && decoded.isNotEmpty) {
          print(
            'UserMedicationsService.fetchAll: first item keys = ${decoded[0].keys}',
          );
        } else if (decoded is Map && decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is List && data.isNotEmpty) {
            print(
              'UserMedicationsService.fetchAll: first data item keys = ${data[0].keys}',
            );
          }
        }
      } catch (_) {}
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
          .map((json) => Medicine.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        'Failed to fetch medications',
        response.statusCode,
        response.body,
      );
    }
  }

  /// POST /api/UserMedications — create a new medication
  static Future<Medicine> create(String token, Medicine medicine) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers(token),
      body: jsonEncode(medicine.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return Medicine.fromJson(decoded);
      }
      // If server returns the created object inside a wrapper
      if (decoded is Map && decoded.containsKey('data')) {
        return Medicine.fromJson(decoded['data'] as Map<String, dynamic>);
      }
      return medicine; // fallback: return original with local id
    } else {
      throw ApiException(
        'Failed to create medication',
        response.statusCode,
        response.body,
      );
    }
  }

  /// PUT /api/UserMedications/{id} — update an existing medication
  static Future<Medicine> update(String token, Medicine medicine) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/${medicine.id}'),
      headers: _headers(token),
      body: jsonEncode(medicine.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Medicine.fromJson(decoded);
        }
      }
      return medicine; // 204 No Content — return the local copy
    } else {
      throw ApiException(
        'Failed to update medication',
        response.statusCode,
        response.body,
      );
    }
  }

  /// DELETE /api/UserMedications/{id} — delete a medication
  static Future<void> delete(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
        'Failed to delete medication',
        response.statusCode,
        response.body,
      );
    }
  }

  /// DELETE /api/UserMedications/myusermeds — delete all user medications
  static Future<void> deleteMyUserMeds(String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/myusermeds'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
        'Failed to delete user medications',
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
  final String responseBody;

  ApiException(this.message, this.statusCode, this.responseBody);

  @override
  String toString() => '$message (HTTP $statusCode): $responseBody';
}

// ─────────────────────────────────────────────────────────────────────────────
// Take Dose Result Model
// ─────────────────────────────────────────────────────────────────────────────

/// Parsed response from POST /api/schedules/{scheduleId}/take
class TakeDoseResult {
  final bool succeeded;
  final String? error;
  final int scheduleId;
  final int? pillsDeducted;
  final int? remainingPills;
  final bool lowStockAlertCreated;

  TakeDoseResult({
    required this.succeeded,
    this.error,
    required this.scheduleId,
    this.pillsDeducted,
    this.remainingPills,
    required this.lowStockAlertCreated,
  });

  factory TakeDoseResult.fromJson(Map<String, dynamic> j) {
    return TakeDoseResult(
      succeeded: j['succeeded'] as bool? ?? false,
      error: j['error']?.toString(),
      scheduleId: j['scheduleId'] as int? ?? 0,
      pillsDeducted: j['pillsDeducted'] as int?,
      remainingPills: j['remainingPills'] as int?,
      lowStockAlertCreated: j['lowStockAlertCreated'] as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedules Service — Take Dose
// ─────────────────────────────────────────────────────────────────────────────

class SchedulesService {
  static const String _baseUrl = 'https://drugsafe.runasp.net/api/schedules';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
    'Authorization': 'Bearer $token',
  };

  /// POST /api/schedules/{scheduleId}/take
  ///
  /// Marks a scheduled dose as taken. The backend deducts [pillsPerDose] from
  /// the user's current pill count and optionally creates a low-stock alert.
  static Future<TakeDoseResult> takeDose(
    String token,
    int scheduleId,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/$scheduleId/take'),
          headers: _headers(token),
          body: '{}', // empty body — some servers require a non-null body
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return TakeDoseResult.fromJson(decoded);
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized. Please sign in again.', 401, response.body);
    } else if (response.statusCode == 404) {
      throw ApiException('Schedule not found or access denied.', 404, response.body);
    } else if (response.statusCode == 400) {
      // Try to surface the backend message
      try {
        final decoded = jsonDecode(response.body);
        final msg = decoded['message'] ?? decoded['error'] ?? 'Bad request.';
        throw ApiException(msg.toString(), 400, response.body);
      } catch (_) {
        throw ApiException('Bad request.', 400, response.body);
      }
    } else {
      throw ApiException(
        'Failed to take dose (${response.statusCode}).',
        response.statusCode,
        response.body,
      );
    }
  }
}

