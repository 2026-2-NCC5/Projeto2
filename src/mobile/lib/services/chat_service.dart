import 'dart:convert';
import 'package:asa_connect/models/chat_message.dart';
import 'package:asa_connect/models/conversation.dart';
import 'package:asa_connect/models/escalation.dart';
import 'package:asa_connect/services/api_client.dart';

class ChatService {
  final ApiClient _client = ApiClient();

  Future<ChatMessageModel> sendMessage({
    required String query,
    String? conversationId,
  }) async {
    final response = await _client.post('/chat', {
      'query': query,
      if (conversationId != null) 'conversation_id': conversationId,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return ChatMessageModel.fromJson(data);
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Erro ao processar mensagem.');
    }
  }

  Future<List<ConversationModel>> getConversations() async {
    final response = await _client.get('/chat/conversations');
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((item) => ConversationModel.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar histórico de conversas.');
    }
  }

  Future<List<ChatMessageModel>> getConversationMessages(String conversationId) async {
    final response = await _client.get('/chat/conversations/$conversationId');
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> msgList = data['messages'] ?? [];
      return msgList.map((item) => ChatMessageModel.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar mensagens da conversa.');
    }
  }

  Future<void> sendFeedback({
    required String messageId,
    required bool isHelpful,
    String? comment,
  }) async {
    await _client.post('/feedback', {
      'message_id': messageId,
      'is_helpful': isHelpful,
      if (comment != null) 'comment': comment,
    });
  }

  Future<EscalationModel> escalateToHuman({
    required String conversationId,
    required String reason,
    String? userNotes,
  }) async {
    final response = await _client.post('/escalations', {
      'conversation_id': conversationId,
      'reason': reason,
      if (userNotes != null) 'user_notes': userNotes,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return EscalationModel.fromJson(data);
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Erro ao solicitar atendimento humano.');
    }
  }
}
