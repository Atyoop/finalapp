import 'package:flutter/material.dart';
import 'medicine.dart';

class HiveMedicine {
  String id;
  String name;
  String dosage;
  String doseAmount;
  int initialStock;
  int? currentPillCount;
  int? lowStockThreshold;
  bool notificationActive;
  String? scheduleType;
  String? frequency;
  int? intervalHours;
  int? pillsPerDose;
  String? note;
  String? expiryDate;
  int timeHour;
  int timeMinute;
  bool hasInteractions;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;

  HiveMedicine({
    this.id = '',
    required this.name,
    this.dosage = '',
    this.doseAmount = '',
    this.initialStock = 0,
    this.currentPillCount,
    this.lowStockThreshold,
    this.notificationActive = true,
    this.scheduleType,
    this.frequency,
    this.intervalHours,
    this.pillsPerDose,
    this.note,
    this.expiryDate,
    this.timeHour = 9,
    this.timeMinute = 0,
    this.hasInteractions = false,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: timeHour, minute: timeMinute);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'doseAmount': doseAmount,
    'initialStock': initialStock,
    'currentPillCount': currentPillCount,
    'lowStockThreshold': lowStockThreshold,
    'notificationActive': notificationActive,
    'scheduleType': scheduleType,
    'frequency': frequency,
    'intervalHours': intervalHours,
    'pillsPerDose': pillsPerDose,
    'note': note,
    'expiryDate': expiryDate,
    'timeHour': timeHour,
    'timeMinute': timeMinute,
    'hasInteractions': hasInteractions,
    'imageUrl': imageUrl,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory HiveMedicine.fromMap(Map<String, dynamic> m) => HiveMedicine(
    id: m['id'] as String? ?? '',
    name: m['name'] as String? ?? '',
    dosage: m['dosage'] as String? ?? '',
    doseAmount: m['doseAmount'] as String? ?? '',
    initialStock: m['initialStock'] as int? ?? 0,
    currentPillCount: m['currentPillCount'] as int?,
    lowStockThreshold: m['lowStockThreshold'] as int?,
    notificationActive: m['notificationActive'] as bool? ?? true,
    scheduleType: m['scheduleType'] as String?,
    frequency: m['frequency'] as String?,
    intervalHours: m['intervalHours'] as int?,
    pillsPerDose: m['pillsPerDose'] as int?,
    note: m['note'] as String?,
    expiryDate: m['expiryDate'] as String?,
    timeHour: m['timeHour'] as int? ?? 9,
    timeMinute: m['timeMinute'] as int? ?? 0,
    hasInteractions: m['hasInteractions'] as bool? ?? false,
    imageUrl: m['imageUrl'] as String?,
    createdAt: m['createdAt'] as String?,
    updatedAt: m['updatedAt'] as String?,
  );

  Medicine toMedicine() => Medicine(
    id: id,
    name: name,
    dosage: dosage,
    doseAmount: doseAmount,
    initialStock: initialStock,
    currentPillCount: currentPillCount,
    initialPillCount: initialStock,
    lowStockThreshold: lowStockThreshold,
    notificationActive: notificationActive,
    scheduleType: scheduleType,
    frequency: frequency ?? '',
    intervalHours: intervalHours,
    pillsPerDose: pillsPerDose,
    note: note ?? '',
    expiryDate: expiryDate != null
        ? DateTime.tryParse(expiryDate!) ?? DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 365)),
    time: timeOfDay,
    hasInteractions: hasInteractions,
    imageUrl: imageUrl ?? '',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 30)),
    deadlineDate: DateTime.now().add(const Duration(days: 16)),
    status: MedicineStatus.scheduled,
    interactions: const [],
  );

  factory HiveMedicine.fromMedicine(Medicine m) => HiveMedicine(
    id: m.id,
    name: m.name,
    dosage: m.dosage ?? '',
    doseAmount: m.doseAmount,
    initialStock: m.initialStock,
    currentPillCount: m.currentPillCount,
    lowStockThreshold: m.lowStockThreshold,
    notificationActive: m.notificationActive,
    scheduleType: m.scheduleType,
    frequency: m.frequency,
    intervalHours: m.intervalHours,
    pillsPerDose: m.pillsPerDose,
    note: m.note.isNotEmpty ? m.note : null,
    expiryDate: m.expiryDate.toString().split(' ').first,
    timeHour: m.time.hour,
    timeMinute: m.time.minute,
    hasInteractions: m.hasInteractions,
    imageUrl: m.imageUrl.isNotEmpty ? m.imageUrl : null,
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );
}
