class ChatConversationSummary {
  final int id;
  final String conversationId;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;

  const ChatConversationSummary({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatConversationSummary.fromJson(Map<String, dynamic> json) {
    return ChatConversationSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId:
          (json['conversationId'] ?? json['conversation_id'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      lastMessage:
          (json['lastMessage'] ?? json['last_message'])?.toString() ?? '',
      updatedAt:
          DateTime.tryParse(
            (json['updatedAt'] ?? json['updated_at'])?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class ChatHistoryMessage {
  final String role;
  final String content;
  final DateTime createdAt;
  final String? detectedLanguage;
  final String? intent;
  final List<String> matchedDrugs;
  final List<String> safetyFlags;

  const ChatHistoryMessage({
    required this.role,
    required this.content,
    required this.createdAt,
    this.detectedLanguage,
    this.intent,
    this.matchedDrugs = const [],
    this.safetyFlags = const [],
  });

  bool get isAssistant => role.toLowerCase() == 'assistant';

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    return ChatHistoryMessage(
      role: json['role']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      detectedLanguage: (json['detectedLanguage'] ?? json['detected_language'])
          ?.toString(),
      intent: json['intent']?.toString(),
      matchedDrugs: _stringList(json['matchedDrugs'] ?? json['matched_drugs']),
      safetyFlags: _stringList(json['safetyFlags'] ?? json['safety_flags']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .where((item) => item != null)
        .map((item) => item.toString())
        .toList(growable: false);
  }
}
