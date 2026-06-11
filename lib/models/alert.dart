class Alert {
  final int id;
  final String? title;
  final String? message;
  final String? type;
  final DateTime? createdAt;
  final bool isRead;
  final String? scheduledAt;
  final String? medicationName;

  Alert({
    required this.id,
    this.title,
    this.message,
    this.type,
    this.createdAt,
    required this.isRead,
    this.scheduledAt,
    this.medicationName,
  });

  /// Parse from JSON response (handles both camelCase and PascalCase)
  factory Alert.fromJson(Map<String, dynamic> json) {
    // Handle isRead (could be 'isRead' or 'IsRead')
    final isRead = json['isRead'] as bool? ?? json['IsRead'] as bool? ?? false;

    // Parse createdAt safely
    DateTime? createdAt;
    try {
      final createdAtStr = json['createdAt'] ?? json['CreatedAt'];
      if (createdAtStr is String) {
        createdAt = DateTime.tryParse(createdAtStr);
      }
    } catch (_) {}

    return Alert(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      title: (json['title'] ?? json['Title']) as String?,
      message: (json['message'] ?? json['Message']) as String?,
      type: (json['type'] ?? json['Type']) as String?,
      createdAt: createdAt,
      isRead: isRead,
      scheduledAt: (json['scheduledAt'] ?? json['ScheduledAt']) as String?,
      medicationName:
          (json['medicationName'] ?? json['MedicationName']) as String?,
    );
  }

  @override
  String toString() =>
      'Alert(id: $id, title: $title, isRead: $isRead, createdAt: $createdAt)';
}
