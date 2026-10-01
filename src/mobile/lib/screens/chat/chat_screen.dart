import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/state/chat_provider.dart';
import 'package:asa_connect/widgets/chat/agent_message_bubble.dart';
import 'package:asa_connect/widgets/chat/user_message_bubble.dart';
import 'package:file_picker/file_picker.dart';
import 'package:asa_connect/services/document_service.dart';
import 'package:asa_connect/services/tts_service.dart';
import 'package:asa_connect/widgets/common/app_header.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;

  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (widget.conversationId != null) {
        chatProvider.loadConversation(widget.conversationId!);
      }
    });
  }

  @override
  void dispose() {
    try {
      Provider.of<TtsService>(context, listen: false).stop();
    } catch (_) {}
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Interrompe fala anterior ao enviar nova mensagem
    try {
      Provider.of<TtsService>(context, listen: false).stop();
    } catch (_) {}

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _showImagePreviewAndSendModal({
    required Uint8List bytes,
    required String filename,
  }) async {
    final commentController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Analisar Erro ou Procedimento com IA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'O ASA Connect examinará esta imagem para identificar o erro ou tela e fornecer a orientação oficial da FECAP.',
              style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
            ),
            const SizedBox(height: 14),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Alguma observação adicional? (opcional)...',
                hintStyle: TextStyle(fontSize: 13, color: context.secondaryTextColor),
                filled: true,
                fillColor: context.inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Enviar para Análise da IA',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                chatProvider.sendImageMessage(
                  imageBytes: bytes,
                  filename: filename,
                  caption: commentController.text.trim(),
                );
                _scrollToBottom();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _attachDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      if (!mounted) return;

      final ext = (picked.extension ?? '').toLowerCase();

      // Se for imagem (captura de tela ou foto de erro), usa a IA de Visão Multimodal
      if (['png', 'jpg', 'jpeg'].contains(ext)) {
        Uint8List? bytes = picked.bytes;
        if (bytes == null && picked.path != null) {
          bytes = await File(picked.path!).readAsBytes();
        }
        if (bytes != null) {
          await _showImagePreviewAndSendModal(bytes: bytes, filename: picked.name);
          return;
        }
      }

      // Se for PDF ou outro arquivo formal, faz o upload documental padrão
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Enviando e validando ${picked.name}...')),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      final docService = DocumentService();
      final uploadResult = await docService.uploadStudentDocument(
        filePath: picked.path,
        fileBytes: picked.bytes,
        filename: picked.name,
        category: 'Chat',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Documento ${picked.name} anexado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.sendMessage(
        'Enviei o documento "${uploadResult.document.originalFilename}" (${uploadResult.document.formattedSize}) para validação no ASA Connect+. '
        'Quais são os critérios de conformidade e prazos da FECAP para este documento?',
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  void _showEscalationDialog(BuildContext context, {String defaultReason = "Dúvida institucional"}) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Falar com o ASA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deseja transferir esta conversa para a fila de atendimento humano do ASA?',
              style: TextStyle(fontSize: 13, color: AppColors.textBody),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Detalhes da sua dúvida para o atendente (opcional)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () async {
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              final success = await chatProvider.escalateToHuman(
                defaultReason,
                userNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
              );
              if (!mounted) return;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Solicitação enviada! Um atendente do ASA entrará em contato.'
                        : 'Você precisa enviar uma mensagem antes de escalonar a conversa.',
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('Confirmar Transferência'),
          ),
        ],
      ),
    );
  }

  void _showSessionInfoDialog(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Sessão ASA Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSessionRow('ID da Conversa:', chatProvider.activeConversationId ?? 'Nova Conversa'),
            _buildSessionRow('Motor RAG:', 'BM25 Híbrido + Embeddings Vetoriais'),
            _buildSessionRow('Versão do Agente:', 'asa-rag-v1.0 (Auditável)'),
            _buildSessionRow('Status da Conexão:', 'Online • Base Supabase Oficial'),
            _buildSessionRow('Total de Mensagens:', '${chatProvider.messages.length} carregadas'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final messages = chatProvider.messages;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppHeader(
        variant: AppHeaderVariant.chat,
        title: 'ASA Connect IA',
        subtitle: 'Online • FECAP',
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 20),
            tooltip: 'Falar com o ASA (Atendimento Humano)',
            onPressed: () => _showEscalationDialog(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
            onSelected: (val) {
              if (val == 'new_chat') {
                chatProvider.startNewChat();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nova conversa iniciada.'), backgroundColor: AppColors.success),
                );
              } else if (val == 'escalate') {
                _showEscalationDialog(context);
              } else if (val == 'info') {
                _showSessionInfoDialog(context, chatProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.add_comment_outlined, size: 18, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text('Nova Conversa'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'escalate',
                child: Row(
                  children: [
                    Icon(Icons.headset_mic_outlined, size: 18, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text('Falar com o ASA'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text('Informações da Sessão'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de Mensagens
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: messages.length + (chatProvider.isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < messages.length) {
                  final msg = messages[index];
                  if (msg.sender == 'USER') {
                    return UserMessageBubble(message: msg);
                  } else {
                    return AgentMessageBubble(
                      message: msg,
                      onFeedback: (isHelpful) {
                        chatProvider.setFeedback(msg.id, isHelpful);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isHelpful ? 'Obrigado pelo feedback positivo!' : 'Feedback registrado para melhoria.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onEscalate: () => _showEscalationDialog(
                        context,
                        defaultReason: msg.isAbstained ? "Abstenção do Agente: Incerteza na resposta" : "Solicitado pelo Aluno",
                      ),
                    );
                  }
                } else {
                  // Indicador de Carregamento / Digitando
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Consultando base institucional oficial...',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          // Barra de Input Inferior (Figma tela 11)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.isDarkMode ? AppDarkColors.surfaceCard : Colors.white,
              border: Border(top: BorderSide(color: context.borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Ícone de Anexo
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.textMuted, size: 22),
                    tooltip: 'Anexar documento',
                    onPressed: _attachDocument,
                  ),

                  // Campo de Texto
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? AppDarkColors.surfaceInput : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: TextStyle(fontSize: 14, color: context.primaryTextColor),
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Digite sua mensagem...',
                                hintStyle: TextStyle(color: context.secondaryTextColor, fontSize: 13),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          // Ícone Microfone
                          IconButton(
                            icon: const Icon(Icons.mic_none_rounded, color: AppColors.textMuted, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Comando de voz ativado (microfone institucional).')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botão de Envio (Círculo Verde)
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
