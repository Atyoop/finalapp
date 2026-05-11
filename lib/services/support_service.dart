import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/support_ticket.dart';
import 'api_client.dart';

class SupportService {
  /// Submit a support request
  /// POST /api/support
  static Future<Map<String, dynamic>> submitSupportRequest({
    required String token,
    required String category,
    required String message,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/support',
        data: {'category': category, 'message': message},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Support request submitted: ${response.statusCode}');
      return response.data ?? {};
    } catch (e) {
      debugPrint('❌ Error submitting support request: $e');
      rethrow;
    }
  }

  /// Fetch all support tickets for the current user
  /// GET /api/support/my-tickets
  static Future<List<SupportTicket>> fetchMyTickets({
    required String token,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/support/my-tickets',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      List<SupportTicket> tickets = [];

      if (data is List) {
        tickets = data
            .map((item) => SupportTicket.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data['tickets'] is List) {
        tickets = (data['tickets'] as List)
            .map((item) => SupportTicket.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      debugPrint('✅ Fetched ${tickets.length} support tickets');
      return tickets;
    } catch (e) {
      debugPrint('❌ Error fetching support tickets: $e');
      rethrow;
    }
  }
}
