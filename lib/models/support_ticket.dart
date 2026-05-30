class SupportTicket {
  final int ticketId;
  final String category;
  final String message;
  final String status;
  final DateTime createdAt;
  final String? adminReply;
  final DateTime? repliedAt;

  SupportTicket({
    required this.ticketId,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
    this.adminReply,
    this.repliedAt,
  });

  /// Parse from JSON response
  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      ticketId: json['ticketId'] as int? ?? json['id'] as int? ?? 0,
      category: json['category'] as String? ?? 'Other',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'Open',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      adminReply: json['adminReply'] as String?,
      repliedAt: json['repliedAt'] != null
          ? DateTime.tryParse(json['repliedAt'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'SupportTicket(ticketId: $ticketId, category: $category, status: $status)';
}
