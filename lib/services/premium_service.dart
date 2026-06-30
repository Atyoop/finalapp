import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/premium_status.dart';
import 'api_client.dart';

class PremiumService {
  /// Get current premium status
  /// GET /api/premium/me
  static Future<PremiumStatus> getPremiumStatus({required String token}) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final status = PremiumStatus.fromJson(response.data ?? {});
      debugPrint('✅ Fetched premium status: ${status.isActive}');
      return status;
    } catch (e) {
      debugPrint('❌ Error fetching premium status: $e');
      rethrow;
    }
  }

  /// Activate a premium plan
  /// POST /api/premium/activate
  static Future<Map<String, dynamic>> activatePremium({
    required String token,
    required String plan, // "Month", "ThreeMonths", "Year"
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/premium/activate',
        data: {'plan': plan},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Premium plan activated: $plan');
      return response.data ?? {};
    } catch (e) {
      debugPrint('❌ Error activating premium: $e');
      rethrow;
    }
  }

  /// Cancel premium subscription
  /// POST /api/premium/cancel
  static Future<Map<String, dynamic>> cancelPremium({
    required String token,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/premium/cancel',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Premium subscription cancelled');
      return response.data ?? {};
    } catch (e) {
      debugPrint('❌ Error cancelling premium: $e');
      rethrow;
    }
  }
}
