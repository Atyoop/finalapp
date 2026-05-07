import 'package:flutter/material.dart';

enum MedicineStatus { scheduled, taken, missed, warning }

class Medicine {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime deadlineDate;
  final DateTime expiryDate;
  final String frequency;
  final TimeOfDay time;
  final String doseAmount;
  final int initialStock;
  final String note;
  final String? dosage;
  final int? currentPillCount;
  final int? initialPillCount;
  final int? lowStockThreshold;
  final int? dosesPerPeriod;
  final String? periodUnit;
  final int? periodValue;
  final int? intervalHours;
  final bool notificationActive;
  MedicineStatus status;

  Medicine({
    this.id = '',
    required this.name,
    this.imageUrl = '',
    required this.startDate,
    required this.endDate,
    required this.deadlineDate,
    required this.expiryDate,
    required this.frequency,
    required this.time,
    required this.doseAmount,
    required this.initialStock,
    this.note = '',
    this.dosage,
    this.currentPillCount,
    this.initialPillCount,
    this.lowStockThreshold,
    this.dosesPerPeriod,
    this.periodUnit,
    this.periodValue,
    this.intervalHours,
    this.notificationActive = true,
    this.status = MedicineStatus.scheduled,
  });

  Medicine copyWith({
    String? name,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? deadlineDate,
    DateTime? expiryDate,
    String? frequency,
    TimeOfDay? time,
    String? doseAmount,
    int? initialStock,
    String? note,
    MedicineStatus? status,
    String? dosage,
    int? currentPillCount,
    int? initialPillCount,
    int? lowStockThreshold,
    int? dosesPerPeriod,
    String? periodUnit,
    int? periodValue,
    int? intervalHours,
    bool? notificationActive,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      expiryDate: expiryDate ?? this.expiryDate,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      doseAmount: doseAmount ?? this.doseAmount,
      initialStock: initialStock ?? this.initialStock,
      note: note ?? this.note,
      dosage: dosage ?? this.dosage,
      currentPillCount: currentPillCount ?? this.currentPillCount,
      initialPillCount: initialPillCount ?? this.initialPillCount,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      dosesPerPeriod: dosesPerPeriod ?? this.dosesPerPeriod,
      periodUnit: periodUnit ?? this.periodUnit,
      periodValue: periodValue ?? this.periodValue,
      intervalHours: intervalHours ?? this.intervalHours,
      notificationActive: notificationActive ?? this.notificationActive,
      status: status ?? this.status,
    );
  }

  /// Convert to JSON for API requests (POST / PUT)
  Map<String, dynamic> toJson() {
    return {
      'medId': id,
      'MedicationName': name, // ✅ changed to match API requirement
      'imageUrl': imageUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'deadlineDate': deadlineDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'frequency': frequency,
      'firstDoseTime':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'doseAmount': doseAmount,
      'initialStock': initialStock,
      'note': note,
      'dosage': dosage,
      'currentPillCount': currentPillCount,
      'initialPillCount': initialPillCount,
      'lowStockThreshold': lowStockThreshold,
      'dosesPerPeriod': dosesPerPeriod,
      'periodUnit': periodUnit,
      'periodValue': periodValue,
      'intervalHours': intervalHours,
      'notificationActive': notificationActive,
    };
  }

  /// Create Medicine from API JSON response
  factory Medicine.fromJson(Map<String, dynamic> json) {
    TimeOfDay parsedTime = const TimeOfDay(hour: 9, minute: 0);
    if (json['firstDoseTime'] != null) {
      try {
        final parts = json['firstDoseTime'].toString().split(':');
        parsedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (_) {}
    }

    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return fallback;
      }
    }

    final now = DateTime.now();

    return Medicine(
      // ✅ fixed: check camelCase first, then PascalCase, then generic fallbacks
      id:
          (json['userMedicationId'] ??
                  json['id'] ??
                  json['medicationId'] ??
                  'medId')
              .toString(),
      name: () {
        final candidates = [
          'medicationName',
          'MedicationName',
          'medName',
          'MedName',
          'medname',
          'name',
          'Name',
          'drugName',
          'drugname',
        ];
        for (final key in candidates) {
          if (json.containsKey(key) && json[key] != null) {
            final v = json[key].toString();
            if (v.isNotEmpty) return v;
          }
        }
        return '';
      }(),
      imageUrl: json['imageUrl'] ?? '',
      startDate: parseDate(json['startDate'], now),
      endDate: parseDate(json['endDate'], now.add(const Duration(days: 30))),
      deadlineDate: parseDate(
        json['deadlineDate'],
        now.add(const Duration(days: 16)),
      ),
      expiryDate: parseDate(
        json['expiryDate'],
        now.add(const Duration(days: 365)),
      ),
      frequency: json['frequency'] ?? '',
      time: parsedTime,
      doseAmount: json['doseAmount'] ?? '1 Tablet',
      initialStock: json['initialStock'] ?? 0,
      note: json['note'] ?? '',
      dosage: json['dosage'],
      currentPillCount: json['currentPillCount'],
      initialPillCount: json['initialPillCount'],
      lowStockThreshold: json['lowStockThreshold'],
      dosesPerPeriod: json['dosesPerPeriod'],
      periodUnit: json['periodUnit'],
      periodValue: json['periodValue'],
      intervalHours: json['intervalHours'],
      notificationActive: json['notificationActive'] ?? true,
      status: MedicineStatus.scheduled,
    );
  }
}
