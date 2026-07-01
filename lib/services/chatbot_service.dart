import 'package:dio/dio.dart';

import '../models/chat_history.dart';
import '../models/chatbot_response.dart';
import 'api_client.dart';

class ChatbotService {
  static Future<ChatbotResponse> sendMessage({
    required String token,
    required String message,
    String? conversationId,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/chatbot/message',
        data: {
          'message': message,
          if (conversationId != null && conversationId.isNotEmpty)
            'conversationId': conversationId,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 40),
        ),
      );

      final data = response.data;
      if (data is! Map) {
        throw const ChatbotException(
          'Mighty returned an unexpected response. Please try again.',
        );
      }

      final result = ChatbotResponse.fromJson(Map<String, dynamic>.from(data));
      if (result.answer.trim().isEmpty) {
        throw const ChatbotException(
          'Mighty returned an empty response. Please try again.',
        );
      }
      return result;
    } on DioException catch (error) {
      final data = error.response?.data;
      String? message;
      if (data is Map) {
        message = (data['message'] ?? data['title'])?.toString();
      }

      throw ChatbotException(
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Mighty is temporarily unavailable. Please try again.',
        statusCode: error.response?.statusCode,
      );
    } on ChatbotException {
      rethrow;
    } catch (_) {
      throw const ChatbotException(
        'Mighty is temporarily unavailable. Please try again.',
      );
    }
  }

  static Future<List<ChatConversationSummary>> getConversations({
    required String token,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/chatbot/conversations',
        options: _options(token),
      );
      final data = response.data;
      if (data is! List) {
        throw const ChatbotException('Could not read chat history.');
      }
      return data
          .whereType<Map>()
          .map(
            (item) => ChatConversationSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _fromDio(error, 'Could not load chat history.');
    }
  }

  static Future<List<ChatHistoryMessage>> getMessages({
    required String token,
    required String conversationId,
  }) async {
    try {
      final encodedId = Uri.encodeComponent(conversationId);
      final response = await ApiClient.dio.get(
        '/chatbot/conversations/$encodedId/messages',
        options: _options(token),
      );
      final data = response.data;
      if (data is! List) {
        throw const ChatbotException('Could not read conversation messages.');
      }
      return data
          .whereType<Map>()
          .map(
            (item) =>
                ChatHistoryMessage.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _fromDio(error, 'Could not load this conversation.');
    }
  }

  static Future<void> deleteConversation({
    required String token,
    required String conversationId,
  }) async {
    try {
      final encodedId = Uri.encodeComponent(conversationId);
      await ApiClient.dio.delete(
        '/chatbot/conversations/$encodedId',
        options: _options(token),
      );
    } on DioException catch (error) {
      throw _fromDio(error, 'Could not delete this conversation.');
    }
  }

  static Options _options(String token) => Options(
    headers: {'Authorization': 'Bearer $token'},
    sendTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 40),
  );

  static ChatbotException _fromDio(DioException error, String fallbackMessage) {
    final data = error.response?.data;
    final message = data is Map
        ? (data['message'] ?? data['title'])?.toString()
        : null;
    return ChatbotException(
      message?.trim().isNotEmpty == true ? message!.trim() : fallbackMessage,
      statusCode: error.response?.statusCode,
    );
  }
}

class ChatbotException implements Exception {
  final String message;
  final int? statusCode;

  const ChatbotException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
