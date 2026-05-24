class MedicineScanResponse {
  final bool success;
  final String? medicationName;
  final String? message;

  const MedicineScanResponse({
    required this.success,
    this.medicationName,
    this.message,
  });

  bool get hasMedicationName =>
      medicationName != null && medicationName!.trim().isNotEmpty;

  factory MedicineScanResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json['success'] ?? json['Success'];
    return MedicineScanResponse(
      success: rawSuccess is bool
          ? rawSuccess
          : rawSuccess?.toString().toLowerCase() == 'true',
      medicationName: (json['medicationName'] ?? json['MedicationName'])
          ?.toString(),
      message: (json['message'] ?? json['Message'])?.toString(),
    );
  }
}
