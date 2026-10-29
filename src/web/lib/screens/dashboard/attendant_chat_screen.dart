import 'dart:async';
import 'package:flutter/material.dart';
import 'package:asa_connect/models/escalation.dart';
import 'package:asa_connect/services/chat_service.dart';

class AttendantChatScreen extends StatefulWidget {
  final EscalationModel escalation;

  const AttendantChatScreen({
    super.key,
    required this.escalation,
  });

  @override
  State<AttendantChatScreen> createState() => _AttendantChatScreenState();
}

class _AttendantChatScreenState extends State<AttendantChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  late EscalationModel _currentCase;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _currentCase = widget.escalation;
    _loadMessages();

    // Iniciar atendimento automaticamente se estiver PENDENTE
    if (_currentCase.status == 'PENDENTE') {
      _startAttendance();
    }

    // Polling a cada 3 segundos para novas mensagens (estilo WhatsApp web)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshMessagesSilently();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startAttendance() async {
    try {
      final updated = await _chatService.startAttendance(_currentCase.id);
      if (mounted) {
        setState(() => _currentCase = updated);
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _chatService.getEscalationMessages(_currentCase.id);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshMessagesSilently() async {
    try {
      final msgs = await _chatService.getEscalationMessages(_currentCase.id);
      if (mounted && msgs.length != _messages.length) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _msgController.clear();

    try {
      final newMsg = await _chatService.sendAttendantMessage(_currentCase.id, text);
      if (mounted) {
        setState(() {
          _messages.add(newMsg);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmCloseAttendance() {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Finalizar Atendimento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você está prestes a encerrar o chamado da senha ${_currentCase.ticketNumber ?? "#${_currentCase.id}"}. O aluno receberá a tela para avaliar seu atendimento.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notas de Resolução (RF08)',
                hintText: 'Descreva como o problema foi solucionado...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _closeAttendance(notesController.text.trim());
            },
            child: const Text('Confirmar Encerramento'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeAttendance(String notes) async {
    try {
      final updated = await _chatService.resolveEscalation(
        _currentCase.id,
        notes.isEmpty ? 'Atendimento finalizado pelo atendente ASA.' : notes,
      );
      if (mounted) {
        setState(() => _currentCase = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atendimento encerrado com sucesso!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao encerrar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = _currentCase.studentName ?? 'Aluno';
    final ra = _currentCase.studentRa ?? 'Sem RA';
    final course = _currentCase.studentCourse ?? 'Curso não informado';
    final ticket = _currentCase.ticketNumber ?? '#${_currentCase.id}';
    final isPresencial = _currentCase.modality == 'PRESENCIAL';
    final isResolved = _currentCase.status == 'RESOLVIDO';

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // Fundo clássico WhatsApp
      appBar: AppBar(
        backgroundColor: const Color(0xFF005C4B), // Verde clássico WhatsApp
        foregroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: Colors.white24,
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          studentName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ticket,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'RA: $ra • $course • ${isPresencial ? "🏢 Presencial" : "💬 Online"}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isResolved)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _confirmCloseAttendance,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Encerrar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: const Color(0xFF075E54),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Chip(
                  label: Text('RESOLVIDO', style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner de contexto do chamado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFFF9C4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFFF57F17)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Motivo: ${_currentCase.reason}${_currentCase.userNotes != null ? " • Dúvida: ${_currentCase.userNotes}" : ""}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Lista de Mensagens estilo WhatsApp
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma mensagem nesta conversa ainda.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final sender = msg['sender'] ?? 'USER';
                          final content = msg['content'] ?? '';
                          final isAttendant = sender == 'ATTENDANT';
                          final isAgent = sender == 'AGENT';

                          // Balão do Atendente (Verde WhatsApp à direita)
                          // Balão do Aluno (Branco à esquerda)
                          // Balão do Agente/Bot (Cinza neutro à esquerda)
                          final isMe = isAttendant;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFFE7FFDB) // Balão verde WhatsApp (atendente)
                                    : (isAgent ? const Color(0xFFF0F0F0) : Colors.white),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(2),
                                  bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        isAgent ? '🤖 Agente Virtual ASA' : studentName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: isAgent ? Colors.grey.shade700 : const Color(0xFF005C4B),
                                        ),
                                      ),
                                    ),
                                  if (isMe)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        'Você (Atendente ASA)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Color(0xFF075E54),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    content,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Barra de digitação estilo WhatsApp
          if (!isResolved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: const Color(0xFFF0F2F5),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _msgController,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: 'Digite uma mensagem para o aluno...',
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF005C4B),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Text(
                'Atendimento encerrado em ${_currentCase.resolvedAt?.toLocal().toString().substring(0, 16) ?? ""}. Notas: ${_currentCase.resolutionNotes ?? "Nenhuma"}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
