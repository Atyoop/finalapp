class HiveReminder {
  String medicineId;
  String medicineName;
  String dosage;
  int hour;
  int minute;
  int repeatIntervalHours;
  bool isActive;

  HiveReminder({
    required this.medicineId,
    required this.medicineName,
    this.dosage = '',
    required this.hour,
    required this.minute,
    this.repeatIntervalHours = 24,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'medicineId': medicineId,
    'medicineName': medicineName,
    'dosage': dosage,
    'hour': hour,
    'minute': minute,
    'repeatIntervalHours': repeatIntervalHours,
    'isActive': isActive,
  };

  factory HiveReminder.fromMap(Map<String, dynamic> m) => HiveReminder(
    medicineId: m['medicineId'] as String? ?? '',
    medicineName: m['medicineName'] as String? ?? '',
    dosage: m['dosage'] as String? ?? '',
    hour: m['hour'] as int? ?? 0,
    minute: m['minute'] as int? ?? 0,
    repeatIntervalHours: m['repeatIntervalHours'] as int? ?? 24,
    isActive: m['isActive'] as bool? ?? true,
  );
}
