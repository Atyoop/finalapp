class ChatbotResponse {
  final String answer;
  final String conversationId;
  final String detectedLanguage;
  final String intent;
  final List<String> matchedDrugs;
  final List<String> safetyFlags;

  const ChatbotResponse({
    required this.answer,
    required this.conversationId,
    required this.detectedLanguage,
    required this.intent,
    required this.matchedDrugs,
    required this.safetyFlags,
  });

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      answer: json['answer']?.toString() ?? '',
      conversationId:
          (json['conversation_id'] ?? json['conversationId'])?.toString() ?? '',
      detectedLanguage:
          (json['detected_language'] ?? json['detectedLanguage'])?.toString() ??
          '',
      intent: json['intent']?.toString() ?? '',
      matchedDrugs: _stringList(json['matched_drugs'] ?? json['matchedDrugs']),
      safetyFlags: _stringList(json['safety_flags'] ?? json['safetyFlags']),
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
