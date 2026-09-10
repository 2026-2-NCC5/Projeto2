import 'package:flutter/material.dart';
import 'package:asa_connect/models/chat_message.dart';
import 'package:asa_connect/models/conversation.dart';
import 'package:asa_connect/services/chat_service.dart';

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

  Future<bool> escalateToHuman(String reason, {String? userNotes}) async {
    if (_activeConversationId == null) return false;
    try {
      await _chatService.escalateToHuman(
        conversationId: _activeConversationId!,
        reason: reason,
        userNotes: userNotes,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
