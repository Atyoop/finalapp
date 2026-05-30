import 'package:flutter/foundation.dart';
import 'medicine_storage_service.dart';
import '../models/hive_reminder.dart';

class LocalReminder {
  final String medicineId;
  final String medicineName;
  final String dosage;
  final int hour;
  final int minute;
  final int repeatIntervalHours;
  final bool isActive;

  LocalReminder({
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.hour,
    required this.minute,
    this.repeatIntervalHours = 24,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'medicineId': medicineId,
    'medicineName': medicineName,
    'dosage': dosage,
    'hour': hour,
    'minute': minute,
    'repeatIntervalHours': repeatIntervalHours,
    'isActive': isActive,
  };

  factory LocalReminder.fromJson(Map<String, dynamic> json) => LocalReminder(
    medicineId: json['medicineId'] as String? ?? '',
    medicineName: json['medicineName'] as String? ?? '',
    dosage: json['dosage'] as String? ?? '',
    hour: json['hour'] as int? ?? 0,
    minute: json['minute'] as int? ?? 0,
    repeatIntervalHours: json['repeatIntervalHours'] as int? ?? 24,
    isActive: json['isActive'] as bool? ?? true,
  );

  HiveReminder toHive() => HiveReminder(
    medicineId: medicineId,
    medicineName: medicineName,
    dosage: dosage,
    hour: hour,
    minute: minute,
    repeatIntervalHours: repeatIntervalHours,
    isActive: isActive,
  );

  factory LocalReminder.fromHive(HiveReminder h) => LocalReminder(
    medicineId: h.medicineId,
    medicineName: h.medicineName,
    dosage: h.dosage,
    hour: h.hour,
    minute: h.minute,
    repeatIntervalHours: h.repeatIntervalHours,
    isActive: h.isActive,
  );
}

class ReminderStorageService {
  static Future<List<LocalReminder>> getReminders() async {
    try {
      final reminders = MedicineStorageService.getAllReminders();
      return reminders.map(LocalReminder.fromHive).toList();
    } catch (e) {
      debugPrint('[ReminderStorage] Error reading reminders: $e');
      return [];
    }
  }

  static Future<bool> saveReminder(LocalReminder reminder) async {
    try {
      return await MedicineStorageService.saveReminder(reminder.toHive());
    } catch (e) {
      debugPrint('[ReminderStorage] Error saving reminder: $e');
      return false;
    }
  }

  static Future<bool> deleteReminder(String medicineId) async {
    try {
      return await MedicineStorageService.deleteReminder(medicineId);
    } catch (e) {
      debugPrint('[ReminderStorage] Error deleting reminder: $e');
      return false;
    }
  }

  static Future<bool> toggleReminder(String medicineId, bool isActive) async {
    try {
      return await MedicineStorageService.toggleReminder(medicineId, isActive);
    } catch (e) {
      debugPrint('[ReminderStorage] Error toggling reminder: $e');
      return false;
    }
  }

  static Future<bool> clearAll() async {
    try {
      return await MedicineStorageService.clearAllReminders();
    } catch (e) {
      debugPrint('[ReminderStorage] Error clearing reminders: $e');
      return false;
    }
  }
}
