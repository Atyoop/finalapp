class NotificationSchedule {
  final int scheduleId;
  final int userMedId;
  final int medId;
  final String medName;
  final DateTime scheduledAt;
  final DateTime notificationTime;
  final String status;
  final int pillsPerDose;
  final int currentPillCount;
  final int doseQuantity;
  final int currentQuantity;
  final String quantityUnit;
  final int lowStockThreshold;
  final bool hasInteractions;
  final String title;
  final String message;

  NotificationSchedule({
    required this.scheduleId,
    required this.userMedId,
    required this.medId,
    required this.medName,
    required this.scheduledAt,
    required this.notificationTime,
    required this.status,
    required this.pillsPerDose,
    required this.currentPillCount,
    required this.doseQuantity,
    required this.currentQuantity,
    required this.quantityUnit,
    required this.lowStockThreshold,
    required this.hasInteractions,
    required this.title,
    required this.message,
  });

  /// Parse from JSON response
  factory NotificationSchedule.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      if (val is String) {
        return double.tryParse(val)?.toInt() ?? int.tryParse(val) ?? fallback;
      }
      return fallback;
    }

    DateTime parseUtc(String str) {
      if (str.isEmpty) return DateTime.now();
      String normalized = str;
      if (!str.endsWith('Z')) {
        final tIndex = str.indexOf('T');
        final timePart = tIndex != -1 ? str.substring(tIndex) : str;
        if (!timePart.contains('+') && !timePart.contains('-')) {
          normalized = '${str}Z';
        }
      }
      return DateTime.tryParse(normalized) ?? DateTime.now();
    }

    return NotificationSchedule(
      scheduleId: parseInt(json['scheduleId'], 0),
      userMedId: parseInt(json['userMedId'], 0),
      medId: parseInt(json['medId'], 0),
      medName: json['medName'] as String? ?? '',
      scheduledAt: parseUtc(json['scheduledAt'] as String? ?? ''),
      notificationTime: parseUtc(json['notificationTime'] as String? ?? ''),
      status: json['status'] as String? ?? 'Pending',
      pillsPerDose: parseInt(json['pillsPerDose'] ?? json['doseQuantity'], 1),
      currentPillCount: parseInt(json['currentPillCount'] ?? json['currentQuantity'], 0),
      doseQuantity: parseInt(json['doseQuantity'] ?? json['pillsPerDose'], 1),
      currentQuantity: parseInt(json['currentQuantity'] ?? json['currentPillCount'], 0),
      quantityUnit: json['quantityUnit']?.toString() ?? 'unit',
      lowStockThreshold: parseInt(json['lowStockThreshold'], 2),
      hasInteractions: json['hasInteractions'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'NotificationSchedule(scheduleId: $scheduleId, medName: $medName, status: $status)';
}
