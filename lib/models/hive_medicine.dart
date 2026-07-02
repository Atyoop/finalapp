import 'package:flutter/material.dart';
import 'medicine.dart';

class HiveMedicine {
  String id;
  int? medicationId;
  String name;
  String? canonicalName;
  String dosage;
  String? dosageForm;
  String? quantityUnit;
  String doseAmount;
  int initialStock;
  int? initialQuantity;
  int? currentQuantity;
  int? doseQuantity;
  int? currentPillCount;
  int? lowStockThreshold;
  bool notificationActive;
  int? advanceReminderMinutes;
  String? scheduleType;
  String? frequency;
  int? intervalHours;
  int? pillsPerDose;
  String? note;
  String? expiryDate;
  int timeHour;
  int timeMinute;
  bool hasInteractions;
  bool isOpened;
  String? openedDate;
  int? afterOpeningDurationValue;
  String? afterOpeningDurationUnit;
  String? afterOpeningExpiryDate;
  String? effectiveExpiryDate;
  String? expiryReason;
  String? afterOpeningSource;
  String? afterOpeningWarning;
  bool isCustomMedication;
  bool? supportsInteractions;
  bool? supportsIngredientWarnings;
  String? customMedicationWarning;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;

  HiveMedicine({
    this.id = '',
    this.medicationId,
    required this.name,
    this.canonicalName,
    this.dosage = '',
    this.dosageForm,
    this.quantityUnit,
    this.doseAmount = '',
    this.initialStock = 0,
    this.initialQuantity,
    this.currentQuantity,
    this.doseQuantity,
    this.currentPillCount,
    this.lowStockThreshold,
    this.notificationActive = true,
    this.advanceReminderMinutes,
    this.scheduleType,
    this.frequency,
    this.intervalHours,
    this.pillsPerDose,
    this.note,
    this.expiryDate,
    this.timeHour = 9,
    this.timeMinute = 0,
    this.hasInteractions = false,
    this.isOpened = false,
    this.openedDate,
    this.afterOpeningDurationValue,
    this.afterOpeningDurationUnit,
    this.afterOpeningExpiryDate,
    this.effectiveExpiryDate,
    this.expiryReason,
    this.afterOpeningSource,
    this.afterOpeningWarning,
    this.isCustomMedication = false,
    this.supportsInteractions,
    this.supportsIngredientWarnings,
    this.customMedicationWarning,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: timeHour, minute: timeMinute);

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'medicationId': medicationId,
    'name': name,
    'canonicalName': canonicalName,
    'dosage': dosage,
    'dosageForm': dosageForm,
    'quantityUnit': quantityUnit,
    'doseAmount': doseAmount,
    'initialStock': initialStock,
    'initialQuantity': initialQuantity,
    'currentQuantity': currentQuantity,
    'doseQuantity': doseQuantity,
    'currentPillCount': currentPillCount,
    'lowStockThreshold': lowStockThreshold,
    'notificationActive': notificationActive,
    'advanceReminderMinutes': advanceReminderMinutes,
    'scheduleType': scheduleType,
    'frequency': frequency,
    'intervalHours': intervalHours,
    'pillsPerDose': pillsPerDose,
    'note': note,
    'expiryDate': expiryDate,
    'timeHour': timeHour,
    'timeMinute': timeMinute,
    'hasInteractions': hasInteractions,
    'isOpened': isOpened,
    'openedDate': openedDate,
    'afterOpeningDurationValue': afterOpeningDurationValue,
    'afterOpeningDurationUnit': afterOpeningDurationUnit,
    'afterOpeningExpiryDate': afterOpeningExpiryDate,
    'effectiveExpiryDate': effectiveExpiryDate,
    'expiryReason': expiryReason,
    'afterOpeningSource': afterOpeningSource,
    'afterOpeningWarning': afterOpeningWarning,
    'isCustomMedication': isCustomMedication,
    'supportsInteractions': supportsInteractions,
    'supportsIngredientWarnings': supportsIngredientWarnings,
    'customMedicationWarning': customMedicationWarning,
    'imageUrl': imageUrl,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory HiveMedicine.fromMap(Map<String, dynamic> m) => HiveMedicine(
    id: m['id'] as String? ?? '',
    medicationId: _parseNullableInt(m['medicationId']),
    name: m['name'] as String? ?? '',
    canonicalName: m['canonicalName'] as String?,
    dosage: m['dosage'] as String? ?? '',
    dosageForm: m['dosageForm'] as String?,
    quantityUnit: m['quantityUnit'] as String?,
    doseAmount: m['doseAmount'] as String? ?? '',
    initialStock: m['initialStock'] as int? ?? 0,
    initialQuantity: m['initialQuantity'] as int?,
    currentQuantity: m['currentQuantity'] as int?,
    doseQuantity: m['doseQuantity'] as int?,
    currentPillCount: m['currentPillCount'] as int?,
    lowStockThreshold: m['lowStockThreshold'] as int?,
    notificationActive: m['notificationActive'] as bool? ?? true,
    advanceReminderMinutes: _parseNullableInt(m['advanceReminderMinutes']),
    scheduleType: m['scheduleType'] as String?,
    frequency: m['frequency'] as String?,
    intervalHours: m['intervalHours'] as int?,
    pillsPerDose: m['pillsPerDose'] as int?,
    note: m['note'] as String?,
    expiryDate: m['expiryDate'] as String?,
    timeHour: m['timeHour'] as int? ?? 9,
    timeMinute: m['timeMinute'] as int? ?? 0,
    hasInteractions: m['hasInteractions'] as bool? ?? false,
    isOpened: m['isOpened'] as bool? ?? false,
    openedDate: m['openedDate'] as String?,
    afterOpeningDurationValue: m['afterOpeningDurationValue'] as int?,
    afterOpeningDurationUnit: m['afterOpeningDurationUnit'] as String?,
    afterOpeningExpiryDate: m['afterOpeningExpiryDate'] as String?,
    effectiveExpiryDate: m['effectiveExpiryDate'] as String?,
    expiryReason: m['expiryReason'] as String?,
    afterOpeningSource: m['afterOpeningSource'] as String?,
    afterOpeningWarning: m['afterOpeningWarning'] as String?,
    isCustomMedication: m['isCustomMedication'] as bool? ?? false,
    supportsInteractions: m['supportsInteractions'] as bool?,
    supportsIngredientWarnings: m['supportsIngredientWarnings'] as bool?,
    customMedicationWarning: m['customMedicationWarning'] as String?,
    imageUrl: m['imageUrl'] as String?,
    createdAt: m['createdAt'] as String?,
    updatedAt: m['updatedAt'] as String?,
  );

  Medicine toMedicine() => Medicine(
    id: id,
    medicationId: medicationId,
    name: name,
    canonicalName: canonicalName,
    dosage: dosage,
    dosageForm: dosageForm,
    quantityUnit: quantityUnit,
    doseAmount: doseAmount,
    initialStock: initialStock,
    initialQuantity: initialQuantity,
    currentQuantity: currentQuantity,
    doseQuantity: doseQuantity,
    currentPillCount: currentPillCount ?? currentQuantity,
    initialPillCount: initialQuantity ?? initialStock,
    lowStockThreshold: lowStockThreshold,
    notificationActive: notificationActive,
    advanceReminderMinutes: advanceReminderMinutes,
    scheduleType: scheduleType,
    frequency: frequency ?? '',
    intervalHours: intervalHours,
    pillsPerDose: pillsPerDose,
    note: note ?? '',
    expiryDate: expiryDate != null
        ? DateTime.tryParse(expiryDate!) ??
              DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 365)),
    time: timeOfDay,
    hasInteractions: hasInteractions,
    isOpened: isOpened,
    openedDate: openedDate != null ? DateTime.tryParse(openedDate!) : null,
    afterOpeningDurationValue: afterOpeningDurationValue,
    afterOpeningDurationUnit: afterOpeningDurationUnit,
    afterOpeningExpiryDate: afterOpeningExpiryDate != null
        ? DateTime.tryParse(afterOpeningExpiryDate!)
        : null,
    effectiveExpiryDate: effectiveExpiryDate != null
        ? DateTime.tryParse(effectiveExpiryDate!)
        : null,
    expiryReason: expiryReason,
    afterOpeningSource: afterOpeningSource,
    afterOpeningWarning: afterOpeningWarning,
    isCustomMedication: isCustomMedication,
    supportsInteractions: supportsInteractions,
    supportsIngredientWarnings: supportsIngredientWarnings,
    customMedicationWarning: customMedicationWarning,
    imageUrl: imageUrl ?? '',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 30)),
    deadlineDate: DateTime.now().add(const Duration(days: 16)),
    status: MedicineStatus.scheduled,
    interactions: const [],
  );

  factory HiveMedicine.fromMedicine(Medicine m) => HiveMedicine(
    id: m.id,
    medicationId: m.medicationId,
    name: m.name,
    canonicalName: m.canonicalName,
    dosage: m.dosage ?? '',
    dosageForm: m.dosageForm,
    quantityUnit: m.quantityUnit,
    doseAmount: m.doseAmount,
    initialStock: m.initialStock,
    initialQuantity: m.initialQuantity,
    currentQuantity: m.currentQuantity,
    doseQuantity: m.doseQuantity,
    currentPillCount: m.currentPillCount ?? m.currentQuantity,
    lowStockThreshold: m.lowStockThreshold,
    notificationActive: m.notificationActive,
    advanceReminderMinutes: m.advanceReminderMinutes,
    scheduleType: m.scheduleType,
    frequency: m.frequency,
    intervalHours: m.intervalHours,
    pillsPerDose: m.pillsPerDose ?? m.doseQuantity,
    note: m.note.isNotEmpty ? m.note : null,
    expiryDate: m.expiryDate.toString().split(' ').first,
    timeHour: m.time.hour,
    timeMinute: m.time.minute,
    hasInteractions: m.hasInteractions,
    isOpened: m.isOpened,
    openedDate: m.openedDate?.toIso8601String(),
    afterOpeningDurationValue: m.afterOpeningDurationValue,
    afterOpeningDurationUnit: m.afterOpeningDurationUnit,
    afterOpeningExpiryDate: m.afterOpeningExpiryDate?.toIso8601String(),
    effectiveExpiryDate: m.effectiveExpiryDate?.toIso8601String(),
    expiryReason: m.expiryReason,
    afterOpeningSource: m.afterOpeningSource,
    afterOpeningWarning: m.afterOpeningWarning,
    isCustomMedication: m.isCustomMedication,
    supportsInteractions: m.supportsInteractions,
    supportsIngredientWarnings: m.supportsIngredientWarnings,
    customMedicationWarning: m.customMedicationWarning,
    imageUrl: m.imageUrl.isNotEmpty ? m.imageUrl : null,
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );
}
