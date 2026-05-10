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
  final int lowStockThreshold;
  final bool hasInteractions;

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
    required this.lowStockThreshold,
    required this.hasInteractions,
  });

  /// Parse from JSON response
  factory NotificationSchedule.fromJson(Map<String, dynamic> json) {
    return NotificationSchedule(
      scheduleId: json['scheduleId'] as int? ?? 0,
      userMedId: json['userMedId'] as int? ?? 0,
      medId: json['medId'] as int? ?? 0,
      medName: json['medName'] as String? ?? '',
      scheduledAt:
          DateTime.tryParse(json['scheduledAt'] as String? ?? '') ??
          DateTime.now(),
      notificationTime:
          DateTime.tryParse(json['notificationTime'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'Pending',
      pillsPerDose: json['pillsPerDose'] as int? ?? 1,
      currentPillCount: json['currentPillCount'] as int? ?? 0,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 2,
      hasInteractions: json['hasInteractions'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'NotificationSchedule(scheduleId: $scheduleId, medName: $medName, status: $status)';
}
