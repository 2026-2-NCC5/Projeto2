import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:asa_connect/models/chat_message.dart';
import 'package:asa_connect/models/conversation.dart';
import 'package:asa_connect/services/chat_service.dart';
import 'package:asa_connect/models/escalation.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatMessageModel> _messages = [];
  List<ConversationModel> _conversations = [];
  String? _activeConversationId;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  List<ChatMessageModel> get messages => _messages;
  List<ConversationModel> get conversations => _conversations;
  String? get activeConversationId => _activeConversationId;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  void clearChat() {
    _activeConversationId = null;
    _messages = [];
    _conversations = [];
    _errorMessage = null;
    _isLoading = false;
    _isSending = false;
    notifyListeners();
  }

  void startNewChat() {
    _activeConversationId = null;
    _messages = [
      ChatMessageModel(
        id: 'welcome_msg',
        conversationId: '',
        sender: 'AGENT',
        content: 'Olá! Sou o ASA Connect, seu assistente virtual do sucesso do estudante. Como posso ajudar você hoje?',
        createdAt: DateTime.now(),
      )
    ];
    notifyListeners();
  }

  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      notifyListeners();
      _conversations = await _chatService.getConversations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    await _chatService.deleteConversation(conversationId);
    _conversations.removeWhere((c) => c.id == conversationId);
    if (_activeConversationId == conversationId) {
      clearChat();
    } else {
      notifyListeners();
    }
  }

  Future<void> loadConversation(String conversationId) async {
    try {
      _isLoading = true;
      _activeConversationId = conversationId;
      notifyListeners();
      _messages = await _chatService.getConversationMessages(conversationId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshActiveConversationSilently() async {
    if (_activeConversationId == null || _isSending) return;
    try {
      final latestMessages = await _chatService.getConversationMessages(_activeConversationId!);
      if (latestMessages.length != _messages.length) {
        _messages = latestMessages;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: _activeConversationId ?? '',
      sender: 'USER',
      content: text,
      createdAt: DateTime.now(),
    );

    _messages.add(userMsg);
    _isSending = true;
    notifyListeners();

    try {
      final agentMsg = await _chatService.sendMessage(
        query: text,
        conversationId: _activeConversationId,
      );

      _activeConversationId = agentMsg.conversationId;
      _messages.add(agentMsg);
      _isSending = false;
      notifyListeners();
    } catch (e) {
      _isSending = false;
      _messages.add(
        ChatMessageModel(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: _activeConversationId ?? '',
          sender: 'AGENT',
          content: 'Desculpe, ocorreu uma instabilidade ao consultar a base oficial. Por favor tente novamente ou solicite atendimento humano.',
          isAbstained: true,
          createdAt: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> sendImageMessage({
    required Uint8List imageBytes,
    required String filename,
    String? caption,
  }) async {
    final queryText = (caption != null && caption.trim().isNotEmpty)
        ? caption.trim()
        : 'Estou com esta dúvida/erro mostrado na tela. Como resolvo este procedimento no portal da FECAP?';

    final base64Str = base64Encode(imageBytes);

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: _activeConversationId ?? '',
      sender: 'USER',
      content: queryText,
      imageUrl: 'data:image/png;base64,$base64Str',
      createdAt: DateTime.now(),
    );

    _messages.add(userMsg);
    _isSending = true;
    notifyListeners();

    try {
      final agentMsg = await _chatService.sendMessage(
        query: queryText,
        conversationId: _activeConversationId,
        imageBase64: base64Str,
        imageFilename: filename,
      );

      _activeConversationId = agentMsg.conversationId;
      _messages.add(agentMsg);
      _isSending = false;
      notifyListeners();
    } catch (e) {
      _isSending = false;
      _messages.add(
        ChatMessageModel(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: _activeConversationId ?? '',
          sender: 'AGENT',
          content: 'Ocorreu um erro ao processar a imagem com a IA. Por favor, tente novamente.',
          isAbstained: true,
          createdAt: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> setFeedback(String messageId, bool isHelpful, {String? comment}) async {
    try {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index].isHelpful = isHelpful;
        _messages[index].feedbackComment = comment;
        notifyListeners();
      }
      await _chatService.sendFeedback(messageId: messageId, isHelpful: isHelpful, comment: comment);
    } catch (e) {
      // Ignora falha silenciosa para não travar a experiência
    }
  }

  Future<EscalationModel?> escalateToHuman(
    String reason, {
    String? userNotes,
    String modality = 'ONLINE',
    String priority = 'MEDIA',
  }) async {
    try {
      // Se não tiver conversa ativa, envia uma mensagem inicial para criar uma conversa no backend
      if (_activeConversationId == null) {
        final initialMsg = await _chatService.sendMessage(
          query: 'Solicitação de atendimento com o ASA ($modality).',
        );
        _activeConversationId = initialMsg.conversationId;
        _messages.add(initialMsg);
        notifyListeners();
      }

      final model = await _chatService.escalateToHuman(
        conversationId: _activeConversationId!,
        reason: reason,
        userNotes: userNotes,
        modality: modality,
        priority: priority,
      );
      return model;
    } catch (e) {
      return null;
    }
  }
}
