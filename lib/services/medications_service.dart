import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for public medications endpoints
class MedicationsService {
  static const String _baseUrl = 'https://drugsafe.runasp.net/api/Medications';

  /// GET /api/Medications/all — fetch all public medications
  static Future<List<Map<String, dynamic>>> fetchAllMeds() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/all'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'];
        if (data is List) return data.cast<Map<String, dynamic>>();
      }
      return [];
    } else {
      throw Exception('Failed to fetch AllMeds (HTTP ${response.statusCode})');
    }
  }

  /// Search medications on the server (debounced by caller).
  /// This calls the same endpoint with an optional `query` parameter.
  static Future<List<Map<String, dynamic>>> searchMeds(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/all?query=${Uri.encodeQueryComponent(query)}',
    );
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'];
        if (data is List) return data.cast<Map<String, dynamic>>();
      }
      return [];
    } else {
      throw Exception('Failed to search /all (HTTP ${response.statusCode})');
    }
  }
}
