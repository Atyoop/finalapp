import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/pharmacy_model.dart';
import 'medicine_storage_service.dart';

class PharmacyService {
  static const String _overpassUrl =
      'https://overpass-api.de/api/interpreter';
  static const String _cacheKey = 'cached_pharmacies';

  static Future<List<PharmacyModel>> searchNearbyPharmacies({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
  }) async {
    try {
      final query = '[out:json];'
          'node[amenity=pharmacy](around:$radiusMeters,$latitude,$longitude);'
          'out;';

      final uri = Uri.parse(_overpassUrl);

      debugPrint('[PharmacyService] Querying Overpass (POST)');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'MedReminderApp/1.0 (flutter)',
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint(
          '[PharmacyService] HTTP ${response.statusCode}: ${response.body}',
        );
        final bodyPreview = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw PharmacyException(
          'Server error (${response.statusCode}). Please try again.',
          detail: bodyPreview,
        );
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('json')) {
        debugPrint(
          '[PharmacyService] Unexpected Content-Type: $contentType — body: ${response.body.length > 300 ? '${response.body.substring(0, 300)}...' : response.body}',
        );
        throw PharmacyException(
          'Unexpected response from server. Please try again.',
        );
      }

      late Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[PharmacyService] Invalid JSON: $e');
        throw PharmacyException(
          'Invalid response format. Please try again.',
        );
      }

      final elements = decoded['elements'] as List<dynamic>? ?? [];

      final pharmacies = elements.map((e) {
        return PharmacyModel.fromOverpassJson(
          e as Map<String, dynamic>,
          userLat: latitude,
          userLng: longitude,
        );
      }).toList();

      pharmacies.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      // Cache successful response
      _cachePharmacies(pharmacies);

      debugPrint('[PharmacyService] Found ${pharmacies.length} pharmacies');
      return pharmacies;
    } on TimeoutException {
      debugPrint('[PharmacyService] Request timed out');
      throw PharmacyException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      debugPrint('[PharmacyService] Network error: $e');
      throw PharmacyException('No internet connection. Please check your network.');
    } on PharmacyException {
      rethrow;
    } catch (e) {
      debugPrint('[PharmacyService] Unexpected error: $e');
      throw PharmacyException('An unexpected error occurred. Please try again.');
    }
  }

  /// Load previously cached pharmacies from Hive.
  static List<PharmacyModel> loadCached() {
    try {
      final raw = MedicineStorageService.getSetting<String>(_cacheKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PharmacyModel.fromCacheJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[PharmacyService] Failed to load cache: $e');
      return [];
    }
  }

  static void _cachePharmacies(List<PharmacyModel> pharmacies) {
    try {
      final json = jsonEncode(pharmacies.map((p) => p.toJson()).toList());
      MedicineStorageService.saveSetting(_cacheKey, json);
      debugPrint('[PharmacyService] Cached ${pharmacies.length} pharmacies');
    } catch (e) {
      debugPrint('[PharmacyService] Failed to cache: $e');
    }
  }
}

class PharmacyException implements Exception {
  final String message;
  final String? detail;

  const PharmacyException(this.message, {this.detail});

  @override
  String toString() => message;
}
