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
    String? imageBase64,
    String? imageFilename,
  }) async {
    final Map<String, dynamic> body = {
      'query': query,
      if (conversationId != null) 'conversation_id': conversationId,
      if (imageBase64 != null) 'image_base64': imageBase64,
      if (imageFilename != null) 'image_filename': imageFilename,
    };
    final response = await _client.post('/chat', body);

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

  Future<Map<String, dynamic>> getOperatingStatus() async {
    final response = await _client.get('/escalations/status-hours');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return {'is_open': false, 'message': 'Atendimento do ASA'};
  }

  Future<EscalationModel> escalateToHuman({
    required String conversationId,
    required String reason,
    String? userNotes,
    String modality = 'ONLINE',
    String priority = 'MEDIA',
  }) async {
    final response = await _client.post('/escalations', {
      'conversation_id': conversationId,
      'reason': reason,
      'modality': modality,
      'priority': priority,
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

  // --- Endpoints para Chat ao Vivo do Atendente & Avaliação ---

  Future<List<Map<String, dynamic>>> getEscalationMessages(int caseId) async {
    final response = await _client.get('/escalations/$caseId/messages');
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return List<Map<String, dynamic>>.from(list);
    } else {
      throw Exception('Erro ao carregar mensagens do atendimento.');
    }
  }

  Future<Map<String, dynamic>> sendAttendantMessage(int caseId, String content) async {
    final response = await _client.post('/escalations/$caseId/messages', {
      'content': content,
    });
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Erro ao enviar mensagem.');
    }
  }

  Future<EscalationModel> startAttendance(int caseId) async {
    final response = await _client.patch('/escalations/$caseId/start', {});
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return EscalationModel.fromJson(data);
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Erro ao iniciar atendimento.');
    }
  }

  Future<EscalationModel> resolveEscalation(int caseId, String notes) async {
    final response = await _client.patch('/escalations/$caseId/resolve', {
      'resolution_notes': notes,
      'status': 'RESOLVIDO',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return EscalationModel.fromJson(data);
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Erro ao encerrar atendimento.');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final response = await _client.delete('/chat/conversations/$conversationId');
    if (response.statusCode != 200) {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Erro ao remover conversa.');
    }
  }

  Future<void> rateEscalation(int caseId, int rating, {String? comment}) async {
    final response = await _client.post('/escalations/$caseId/rate', {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    if (response.statusCode != 200) {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Erro ao enviar avaliação.');
    }
  }

  Future<EscalationModel?> getMyActiveEscalation() async {
    final response = await _client.get('/escalations/active-mine');
    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return null;
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return EscalationModel.fromJson(data);
    }
    return null;
  }

  Future<EscalationModel?> getEscalationByConversation(String conversationId) async {
    final response = await _client.get('/escalations/by-conversation/$conversationId');
    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return null;
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return EscalationModel.fromJson(data);
    }
    return null;
  }

  Future<Map<String, dynamic>> getSatisfactionStats() async {
    final response = await _client.get('/escalations/stats/satisfaction');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return {
      'average_rating': 0.0,
      'total_rated': 0,
      'distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      'csat_percent': 0.0,
    };
  }
}
