import 'package:flutter/material.dart';
import '../utils/quantity_helpers.dart';

enum MedicineStatus { scheduled, taken, missed, warning }

/// A single drug–drug interaction returned by the API.
class MedicationInteraction {
  final String withMedication;
  final String reason;

  const MedicationInteraction({
    required this.withMedication,
    required this.reason,
  });

  factory MedicationInteraction.fromJson(Map<String, dynamic> j) {
    return MedicationInteraction(
      withMedication: (j['withMedication'] ?? '').toString(),
      reason: (j['reason'] ?? '').toString(),
    );
  }
}

class Medicine {
  final String id;
  final int? medicationId;
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
  final String? dosageForm;
  final String? quantityUnit;
  final int? initialQuantity;
  final int? currentQuantity;
  final int? doseQuantity;
  final int? currentPillCount;
  final int? initialPillCount;
  final int? lowStockThreshold;
  final int? dosesPerPeriod;
  final String? periodUnit;
  final int? periodValue;
  final int? intervalHours;
  final bool notificationActive;
  final String? scheduleType;
  final List<String>? doseTimes;
  final int? pillsPerDose;
  final bool hasInteractions;
  final List<MedicationInteraction> interactions;
  final bool isOpened;
  final DateTime? openedDate;
  final int? afterOpeningDurationValue;
  final String? afterOpeningDurationUnit;
  final DateTime? afterOpeningExpiryDate;
  final DateTime? effectiveExpiryDate;
  final String? expiryReason;
  final String? afterOpeningSource;
  final String? afterOpeningWarning;
  final bool isCustomMedication;
  final bool? supportsInteractions;
  final bool? supportsIngredientWarnings;
  final String? customMedicationWarning;
  MedicineStatus status;

  Medicine({
    this.id = '',
    this.medicationId,
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
    this.dosageForm,
    this.quantityUnit,
    this.initialQuantity,
    this.currentQuantity,
    this.doseQuantity,
    this.currentPillCount,
    this.initialPillCount,
    this.lowStockThreshold,
    this.dosesPerPeriod,
    this.periodUnit,
    this.periodValue,
    this.intervalHours,
    this.notificationActive = true,
    this.scheduleType,
    this.doseTimes,
    this.pillsPerDose,
    this.hasInteractions = false,
    this.interactions = const [],
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
    this.status = MedicineStatus.scheduled,
  });

  DateTime get actualExpiryDate => effectiveExpiryDate ?? expiryDate;

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
    String? dosageForm,
    String? quantityUnit,
    int? initialQuantity,
    int? currentQuantity,
    int? doseQuantity,
    int? currentPillCount,
    int? initialPillCount,
    int? lowStockThreshold,
    int? dosesPerPeriod,
    String? periodUnit,
    int? periodValue,
    int? intervalHours,
    bool? notificationActive,
    String? scheduleType,
    List<String>? doseTimes,
    int? pillsPerDose,
    bool? hasInteractions,
    List<MedicationInteraction>? interactions,
    bool? isOpened,
    DateTime? openedDate,
    int? afterOpeningDurationValue,
    String? afterOpeningDurationUnit,
    DateTime? afterOpeningExpiryDate,
    DateTime? effectiveExpiryDate,
    String? expiryReason,
    String? afterOpeningSource,
    String? afterOpeningWarning,
    int? medicationId,
    bool? isCustomMedication,
    bool? supportsInteractions,
    bool? supportsIngredientWarnings,
    String? customMedicationWarning,
  }) {
    return Medicine(
      id: id,
      medicationId: medicationId ?? this.medicationId,
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
      dosageForm: dosageForm ?? this.dosageForm,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      doseQuantity: doseQuantity ?? this.doseQuantity,
      currentPillCount: currentPillCount ?? this.currentPillCount,
      initialPillCount: initialPillCount ?? this.initialPillCount,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      dosesPerPeriod: dosesPerPeriod ?? this.dosesPerPeriod,
      periodUnit: periodUnit ?? this.periodUnit,
      periodValue: periodValue ?? this.periodValue,
      intervalHours: intervalHours ?? this.intervalHours,
      notificationActive: notificationActive ?? this.notificationActive,
      scheduleType: scheduleType ?? this.scheduleType,
      doseTimes: doseTimes ?? this.doseTimes,
      pillsPerDose: pillsPerDose ?? this.pillsPerDose,
      hasInteractions: hasInteractions ?? this.hasInteractions,
      interactions: interactions ?? this.interactions,
      isOpened: isOpened ?? this.isOpened,
      openedDate: openedDate ?? this.openedDate,
      afterOpeningDurationValue:
          afterOpeningDurationValue ?? this.afterOpeningDurationValue,
      afterOpeningDurationUnit:
          afterOpeningDurationUnit ?? this.afterOpeningDurationUnit,
      afterOpeningExpiryDate:
          afterOpeningExpiryDate ?? this.afterOpeningExpiryDate,
      effectiveExpiryDate: effectiveExpiryDate ?? this.effectiveExpiryDate,
      expiryReason: expiryReason ?? this.expiryReason,
      afterOpeningSource: afterOpeningSource ?? this.afterOpeningSource,
      afterOpeningWarning: afterOpeningWarning ?? this.afterOpeningWarning,
      isCustomMedication: isCustomMedication ?? this.isCustomMedication,
      supportsInteractions: supportsInteractions ?? this.supportsInteractions,
      supportsIngredientWarnings:
          supportsIngredientWarnings ?? this.supportsIngredientWarnings,
      customMedicationWarning:
          customMedicationWarning ?? this.customMedicationWarning,
      status: status ?? this.status,
    );
  }

  /// Convert to JSON for API requests (POST / PUT)
  /// Maps to the exact backend schema specified
  Map<String, dynamic> toJson() {
    // Format firstDoseTime from TimeOfDay
    final firstDoseTimeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

    // Determine expiryDate string — send null if it equals the fallback
    final expiryStr = expiryDate.toString().split(' ')[0];

    // For Interval schedules, always send empty List<String>
    final List<String> doseTimesJson = scheduleType == 'Interval'
        ? <String>[]
        : (doseTimes ?? <String>[]);
    final effectiveInitialQuantity =
        initialQuantity ?? initialPillCount ?? initialStock;
    final effectiveCurrentQuantity =
        currentQuantity ?? currentPillCount ?? effectiveInitialQuantity;
    final effectiveDoseQuantity = doseQuantity ?? pillsPerDose ?? 1;
    final effectiveQuantityUnit = normalizeQuantityUnit(
      quantityUnit ?? quantityUnitForDosageForm(dosageForm),
    );

    final json = <String, dynamic>{
      'medicationId': isCustomMedication ? null : medicationId,
      'medicationName': name,
      'isCustomMedication': isCustomMedication,
      'dosage': dosage,
      'dosageForm': dosageForm,
      'quantityUnit': effectiveQuantityUnit,
      'initialQuantity': effectiveInitialQuantity,
      'currentQuantity': effectiveCurrentQuantity,
      'doseQuantity': effectiveDoseQuantity,
      'notes': note.isNotEmpty ? note : null,
      'startDate': startDate.toString().split(' ')[0], // YYYY-MM-DD
      'endDate': endDate.toString().split(' ')[0],
      'expiryDate': expiryStr,
      'firstDoseTime': firstDoseTimeStr,
      'currentPillCount': currentPillCount ?? effectiveCurrentQuantity,
      'initialPillCount': initialPillCount ?? effectiveInitialQuantity,
      'lowStockThreshold': lowStockThreshold,
      'dosesPerPeriod': dosesPerPeriod,
      'periodUnit': periodUnit,
      'periodValue': periodValue,
      'intervalHours': intervalHours,
      'notificationActive': notificationActive,
      'scheduleType': scheduleType,
      'doseTimes': doseTimesJson,
      'pillsPerDose': pillsPerDose ?? effectiveDoseQuantity,
      'isOpened': isOpened,
    };

    if (isOpened) {
      json['openedDate'] = openedDate == null
          ? null
          : DateTime.utc(
              openedDate!.year,
              openedDate!.month,
              openedDate!.day,
            ).toIso8601String();
      json['afterOpeningDurationValue'] = afterOpeningDurationValue;
      json['afterOpeningDurationUnit'] = afterOpeningDurationUnit ?? 'days';
    }

    return json;
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

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse(value.toString());
    }

    dynamic readAny(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key)) return json[key];
      }
      return null;
    }

    // Parse doseTimes list - ensure it's List<String>, not List<dynamic>
    final List<String> parsedDoseTimes = <String>[];
    if (json['doseTimes'] != null) {
      try {
        final raw = json['doseTimes'];
        if (raw is List) {
          for (final item in raw) {
            final str = item.toString().trim();
            if (str.isNotEmpty) {
              parsedDoseTimes.add(str);
            }
          }
        }
      } catch (_) {}
    }

    final now = DateTime.now();

    final parsedInitialQuantity = parseInt(
      json['initialQuantity'] ??
          json['initialPillCount'] ??
          json['initialStock'],
    );
    final parsedCurrentQuantity = parseInt(
      json['currentQuantity'] ?? json['currentPillCount'],
    );
    final parsedDoseQuantity = parseInt(
      json['doseQuantity'] ?? json['pillsPerDose'],
    );
    final parsedDosageForm = (json['dosageForm'] ?? json['dosage_Form'])
        ?.toString();
    final parsedQuantityUnit = normalizeQuantityUnit(
      (json['quantityUnit'] ?? quantityUnitForDosageForm(parsedDosageForm))
          ?.toString(),
    );

    return Medicine(
      // ✅ fixed: check camelCase first, then PascalCase, then generic fallbacks
      id: (json['userMedicationId'] ?? json['id'] ?? 'medId').toString(),
      medicationId: parseInt(readAny(['medicationId', 'MedicationId'])),
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
      note: json['note'] ?? json['notes'] ?? '',
      dosage: json['dosage'],
      dosageForm: parsedDosageForm,
      quantityUnit: parsedQuantityUnit,
      initialQuantity: parsedInitialQuantity,
      currentQuantity: parsedCurrentQuantity,
      doseQuantity: parsedDoseQuantity,
      currentPillCount:
          parseInt(json['currentPillCount']) ?? parsedCurrentQuantity,
      initialPillCount:
          parseInt(json['initialPillCount']) ?? parsedInitialQuantity,
      lowStockThreshold: parseInt(json['lowStockThreshold']),
      dosesPerPeriod: parseInt(json['dosesPerPeriod']),
      periodUnit: json['periodUnit'],
      periodValue: parseInt(json['periodValue']),
      intervalHours: parseInt(json['intervalHours']),
      notificationActive: json['notificationActive'] ?? true,
      scheduleType: json['scheduleType'],
      doseTimes: parsedDoseTimes.isNotEmpty ? parsedDoseTimes : null,
      pillsPerDose: parseInt(json['pillsPerDose']) ?? parsedDoseQuantity,
      hasInteractions: json['hasInteractions'] as bool? ?? false,
      interactions: () {
        final raw = json['interactions'];
        if (raw is List) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map(MedicationInteraction.fromJson)
              .toList();
        }
        return <MedicationInteraction>[];
      }(),
      isOpened: readAny(['isOpened', 'IsOpened']) as bool? ?? false,
      openedDate: parseNullableDate(readAny(['openedDate', 'OpenedDate'])),
      afterOpeningDurationValue: parseInt(
        readAny(['afterOpeningDurationValue', 'AfterOpeningDurationValue']),
      ),
      afterOpeningDurationUnit: readAny([
        'afterOpeningDurationUnit',
        'AfterOpeningDurationUnit',
      ])?.toString(),
      afterOpeningExpiryDate: parseNullableDate(
        readAny(['afterOpeningExpiryDate', 'AfterOpeningExpiryDate']),
      ),
      effectiveExpiryDate: parseNullableDate(
        readAny(['effectiveExpiryDate', 'EffectiveExpiryDate']),
      ),
      expiryReason: readAny(['expiryReason', 'ExpiryReason'])?.toString(),
      afterOpeningSource: readAny([
        'afterOpeningSource',
        'AfterOpeningSource',
      ])?.toString(),
      afterOpeningWarning: readAny([
        'afterOpeningWarning',
        'AfterOpeningWarning',
      ])?.toString(),
      isCustomMedication:
          readAny(['isCustomMedication', 'IsCustomMedication']) as bool? ??
          false,
      supportsInteractions:
          readAny(['supportsInteractions', 'SupportsInteractions']) as bool?,
      supportsIngredientWarnings:
          readAny(['supportsIngredientWarnings', 'SupportsIngredientWarnings'])
              as bool?,
      customMedicationWarning: readAny([
        'customMedicationWarning',
        'CustomMedicationWarning',
      ])?.toString(),
      status: MedicineStatus.scheduled,
    );
  }
}
