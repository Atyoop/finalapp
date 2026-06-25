import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_schedule.dart';
import 'api_client.dart';
import 'medicine_storage_service.dart';

class NotificationScheduleService {
  /// Fetch notification schedules from the backend
  /// GET /api/users/me/notification-schedules
  static Future<List<NotificationSchedule>> fetchNotificationSchedules({
    required String token,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/users/me/notification-schedules',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      List<NotificationSchedule> schedules = [];

      if (response.data is List) {
        schedules = (response.data as List)
            .map(
              (item) =>
                  NotificationSchedule.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      final inactiveUserMedIds = MedicineStorageService.getAllMedicines()
          .where((medicine) => !medicine.notificationActive)
          .map((medicine) => int.tryParse(medicine.id))
          .whereType<int>()
          .toSet();

      if (inactiveUserMedIds.isNotEmpty) {
        schedules = schedules
            .where(
              (schedule) => !inactiveUserMedIds.contains(schedule.userMedId),
            )
            .toList();
      }

      debugPrint('✅ Fetched ${schedules.length} notification schedules');
      return schedules;
    } catch (e) {
      debugPrint('❌ Error fetching notification schedules: $e');
      rethrow;
    }
  }
}
