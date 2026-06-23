class ApiParse {
  static dynamic readAny(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) return json[key];
    }
    return null;
  }

  static int? intValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static double? doubleValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool boolValue(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value == null) return fallback;
    final text = value.toString().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return fallback;
  }

  static DateTime? dateValue(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<dynamic> listValue(dynamic value) {
    if (value is List) return value;
    if (value is Map && value['\$values'] is List) {
      return value['\$values'] as List<dynamic>;
    }
    return const [];
  }

  static List<T> parseList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) parser,
  ) {
    return listValue(
      value,
    ).whereType<Map<String, dynamic>>().map(parser).toList();
  }
}

class MedicationAdherenceModel {
  final int? userMedicationId;
  final String medicationName;
  final int taken;
  final int skipped;
  final int missed;
  final int total;
  final double adherenceRate;

  const MedicationAdherenceModel({
    this.userMedicationId,
    required this.medicationName,
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.total,
    required this.adherenceRate,
  });

  factory MedicationAdherenceModel.fromJson(Map<String, dynamic> json) {
    final taken =
        ApiParse.intValue(
          ApiParse.readAny(json, ['taken', 'takenDoses', 'Taken']),
        ) ??
        0;
    final skipped =
        ApiParse.intValue(
          ApiParse.readAny(json, ['skipped', 'skippedDoses', 'Skipped']),
        ) ??
        0;
    final missed =
        ApiParse.intValue(
          ApiParse.readAny(json, ['missed', 'missedDoses', 'Missed']),
        ) ??
        0;
    final total =
        ApiParse.intValue(
          ApiParse.readAny(json, ['total', 'totalDoses', 'Total']),
        ) ??
        (taken + skipped + missed);
    return MedicationAdherenceModel(
      userMedicationId: ApiParse.intValue(
        ApiParse.readAny(json, ['userMedicationId', 'id', 'UserMedicationId']),
      ),
      medicationName:
          ApiParse.readAny(json, [
            'medicationName',
            'name',
            'MedicationName',
          ])?.toString() ??
          '',
      taken: taken,
      skipped: skipped,
      missed: missed,
      total: total,
      adherenceRate:
          ApiParse.doubleValue(
            ApiParse.readAny(json, [
              'adherenceRate',
              'adherencePercentage',
              'percentage',
              'AdherenceRate',
            ]),
          ) ??
          0,
    );
  }
}

class AdherenceSummaryModel {
  final int taken;
  final int skipped;
  final int missed;
  final int total;
  final double adherenceRate;
  final List<MedicationAdherenceModel> medications;

  const AdherenceSummaryModel({
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.total,
    required this.adherenceRate,
    required this.medications,
  });

  factory AdherenceSummaryModel.fromJson(Map<String, dynamic> json) {
    final meds = ApiParse.parseList(
      ApiParse.readAny(json, ['medications', 'items', 'data', 'Medications']),
      MedicationAdherenceModel.fromJson,
    );
    final taken =
        ApiParse.intValue(ApiParse.readAny(json, ['taken', 'takenDoses'])) ??
        meds.fold<int>(0, (sum, med) => sum + med.taken);
    final skipped =
        ApiParse.intValue(
          ApiParse.readAny(json, ['skipped', 'skippedDoses']),
        ) ??
        meds.fold<int>(0, (sum, med) => sum + med.skipped);
    final missed =
        ApiParse.intValue(ApiParse.readAny(json, ['missed', 'missedDoses'])) ??
        meds.fold<int>(0, (sum, med) => sum + med.missed);
    final total =
        ApiParse.intValue(ApiParse.readAny(json, ['total', 'totalDoses'])) ??
        (taken + skipped + missed);
    return AdherenceSummaryModel(
      taken: taken,
      skipped: skipped,
      missed: missed,
      total: total,
      adherenceRate:
          ApiParse.doubleValue(
            ApiParse.readAny(json, [
              'adherenceRate',
              'adherencePercentage',
              'percentage',
            ]),
          ) ??
          (total == 0 ? 0 : (taken / total) * 100),
      medications: meds,
    );
  }
}

class DoseHistoryModel {
  final int? scheduleId;
  final int? userMedicationId;
  final String medicationName;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? actionAt;
  final String? reason;
  final String? note;

  const DoseHistoryModel({
    this.scheduleId,
    this.userMedicationId,
    required this.medicationName,
    required this.status,
    this.scheduledAt,
    this.actionAt,
    this.reason,
    this.note,
  });

  factory DoseHistoryModel.fromJson(Map<String, dynamic> json) {
    return DoseHistoryModel(
      scheduleId: ApiParse.intValue(
        ApiParse.readAny(json, ['scheduleId', 'id']),
      ),
      userMedicationId: ApiParse.intValue(
        ApiParse.readAny(json, ['userMedicationId', 'UserMedicationId']),
      ),
      medicationName:
          ApiParse.readAny(json, [
            'medicationName',
            'medName',
            'name',
          ])?.toString() ??
          '',
      status: ApiParse.readAny(json, ['status', 'Status'])?.toString() ?? '',
      scheduledAt: ApiParse.dateValue(
        ApiParse.readAny(json, ['scheduledAt', 'notificationTime']),
      ),
      actionAt: ApiParse.dateValue(
        ApiParse.readAny(json, [
          'takenAt',
          'skippedAt',
          'missedAt',
          'actionAt',
        ]),
      ),
      reason: ApiParse.readAny(json, [
        'reason',
        'skipReason',
        'missedReason',
      ])?.toString(),
      note: ApiParse.readAny(json, ['note', 'notes', 'actionNote'])?.toString(),
    );
  }
}

class MedicationIntakeLogModel {
  final int? id;
  final int? userMedicationId;
  final String medicationName;
  final DateTime? takenAt;
  final double? quantityTaken;
  final String? quantityUnit;
  final String? reason;
  final String? notes;

  const MedicationIntakeLogModel({
    this.id,
    this.userMedicationId,
    required this.medicationName,
    this.takenAt,
    this.quantityTaken,
    this.quantityUnit,
    this.reason,
    this.notes,
  });

  factory MedicationIntakeLogModel.fromJson(Map<String, dynamic> json) {
    return MedicationIntakeLogModel(
      id: ApiParse.intValue(ApiParse.readAny(json, ['id', 'intakeLogId'])),
      userMedicationId: ApiParse.intValue(
        ApiParse.readAny(json, ['userMedicationId', 'UserMedicationId']),
      ),
      medicationName:
          ApiParse.readAny(json, ['medicationName', 'name'])?.toString() ?? '',
      takenAt: ApiParse.dateValue(ApiParse.readAny(json, ['takenAt', 'date'])),
      quantityTaken: ApiParse.doubleValue(
        ApiParse.readAny(json, ['quantityTaken', 'doseQuantity']),
      ),
      quantityUnit: ApiParse.readAny(json, ['quantityUnit'])?.toString(),
      reason: ApiParse.readAny(json, ['reason'])?.toString(),
      notes: ApiParse.readAny(json, ['notes', 'note'])?.toString(),
    );
  }
}

class CabinetMedicationModel {
  final int? userMedicationId;
  final String medicationName;
  final int? currentQuantity;
  final String? quantityUnit;
  final DateTime? effectiveExpiryDate;
  final int? daysUntilEmpty;
  final int? daysUntilExpiry;
  final bool refillWarning;
  final String? status;

  const CabinetMedicationModel({
    this.userMedicationId,
    required this.medicationName,
    this.currentQuantity,
    this.quantityUnit,
    this.effectiveExpiryDate,
    this.daysUntilEmpty,
    this.daysUntilExpiry,
    this.refillWarning = false,
    this.status,
  });

  factory CabinetMedicationModel.fromJson(Map<String, dynamic> json) {
    return CabinetMedicationModel(
      userMedicationId: ApiParse.intValue(
        ApiParse.readAny(json, ['userMedicationId', 'id']),
      ),
      medicationName:
          ApiParse.readAny(json, ['medicationName', 'name'])?.toString() ?? '',
      currentQuantity: ApiParse.intValue(
        ApiParse.readAny(json, ['currentQuantity', 'currentPillCount']),
      ),
      quantityUnit: ApiParse.readAny(json, ['quantityUnit'])?.toString(),
      effectiveExpiryDate: ApiParse.dateValue(
        ApiParse.readAny(json, ['effectiveExpiryDate', 'expiryDate']),
      ),
      daysUntilEmpty: ApiParse.intValue(
        ApiParse.readAny(json, ['daysUntilEmpty']),
      ),
      daysUntilExpiry: ApiParse.intValue(
        ApiParse.readAny(json, ['daysUntilExpiry']),
      ),
      refillWarning: ApiParse.boolValue(
        ApiParse.readAny(json, ['refillWarning']),
      ),
      status: ApiParse.readAny(json, ['status', 'reason'])?.toString(),
    );
  }
}

class CabinetHealthModel {
  final List<CabinetMedicationModel> expired;
  final List<CabinetMedicationModel> expiringSoon;
  final List<CabinetMedicationModel> afterOpeningExpiringSoon;
  final List<CabinetMedicationModel> lowStock;
  final List<CabinetMedicationModel> outOfStock;
  final List<CabinetMedicationModel> runningOutSoon;
  final List<CabinetMedicationModel> healthy;

  const CabinetHealthModel({
    this.expired = const [],
    this.expiringSoon = const [],
    this.afterOpeningExpiringSoon = const [],
    this.lowStock = const [],
    this.outOfStock = const [],
    this.runningOutSoon = const [],
    this.healthy = const [],
  });

  int get attentionCount =>
      expired.length +
      expiringSoon.length +
      afterOpeningExpiringSoon.length +
      lowStock.length +
      outOfStock.length +
      runningOutSoon.length;

  factory CabinetHealthModel.fromJson(Map<String, dynamic> json) {
    List<CabinetMedicationModel> meds(String key) {
      return ApiParse.parseList(json[key], CabinetMedicationModel.fromJson);
    }

    return CabinetHealthModel(
      expired: meds('expired'),
      expiringSoon: meds('expiringSoon'),
      afterOpeningExpiringSoon: meds('afterOpeningExpiringSoon'),
      lowStock: meds('lowStock'),
      outOfStock: meds('outOfStock'),
      runningOutSoon: meds('runningOutSoon'),
      healthy: meds('healthy'),
    );
  }
}
