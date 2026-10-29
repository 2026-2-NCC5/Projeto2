import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/models/escalation.dart';
import 'package:asa_connect/services/chat_service.dart';
import 'package:asa_connect/state/chat_provider.dart';

class AsaTicketModal extends StatefulWidget {
  final String defaultReason;

  const AsaTicketModal({
    super.key,
    this.defaultReason = "Dúvida com atendente do ASA",
  });

  static Future<void> show(BuildContext context, {String defaultReason = "Dúvida com atendente do ASA"}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AsaTicketModal(defaultReason: defaultReason),
    );
  }

  @override
  State<AsaTicketModal> createState() => _AsaTicketModalState();
}

class _AsaTicketModalState extends State<AsaTicketModal> {
  final TextEditingController _notesController = TextEditingController();
  final ChatService _chatService = ChatService();

  String _modality = 'PRESENCIAL'; // 'PRESENCIAL' ou 'ONLINE'
  String _priority = 'MEDIA'; // 'MEDIA' (Geral) ou 'ALTA' (Prioritário)
  bool _isLoadingHours = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _operatingStatus;
  EscalationModel? _createdTicket;

  @override
  void initState() {
    super.initState();
    _fetchOperatingHours();
  }

  Future<void> _fetchOperatingHours() async {
    try {
      final status = await _chatService.getOperatingStatus();
      final existingTicket = await _chatService.getMyActiveEscalation();
      if (mounted) {
        setState(() {
          _operatingStatus = status;
          if (existingTicket != null) {
            _createdTicket = existingTicket;
          }
          _isLoadingHours = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingHours = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _operatingStatus?['is_open'] ?? true;

    if (_isLoadingHours) {
      return Dialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando disponibilidade...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        child: _createdTicket != null ? _buildTicketGeneratedView() : _buildFormView(isOpen),
      ),
    );
  }

  Widget _buildFormView(bool isOpen) {
    final isDark = context.isDarkMode;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.confirmation_number_rounded, color: AppColors.primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retirar Senha / Falar com o ASA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.primaryTextColor,
                      ),
                    ),
                    Text(
                      'Ouvidoria e Sucesso do Aluno Alvarista',
                      style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Banner de Horário de Atendimento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isOpen
                  ? (isDark ? const Color(0xFF063A25) : const Color(0xFFDCFCE7))
                  : (isDark ? const Color(0xFF381A1A) : const Color(0xFFFEE2E2)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOpen
                    ? (isDark ? const Color(0xFF00E387) : const Color(0xFF86EFAC))
                    : (isDark ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOpen ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  color: isOpen ? (isDark ? const Color(0xFF00E387) : const Color(0xFF16A34A)) : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _operatingStatus?['message'] ?? (isOpen ? 'ASA Aberto para Atendimento' : 'Atendimento Fechado'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? (isDark ? const Color(0xFF00E387) : const Color(0xFF15803D)) : AppColors.error,
                        ),
                      ),
                      Text(
                        _operatingStatus?['schedule'] ?? 'Seg-Sex: 09h00 às 21h00 | Sáb: 09h00 às 12h30',
                        style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Escolha da Modalidade (Presencial vs Online)
          Text(
            'Escolha como deseja ser atendido:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primaryTextColor),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildModalityCard(
                  title: 'Presencial',
                  subtitle: 'Balcão / Mesa ASA',
                  icon: Icons.storefront_rounded,
                  value: 'PRESENCIAL',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModalityCard(
                  title: 'Online',
                  subtitle: 'Chat com Atendente',
                  icon: Icons.chat_bubble_outline_rounded,
                  value: 'ONLINE',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Tipo de Fila (Geral vs Prioritária)
          Text(
            'Tipo de Atendimento:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primaryTextColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Fila Geral (Normal)'),
                selected: _priority == 'MEDIA',
                selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _priority == 'MEDIA' ? AppColors.primaryGreen : context.secondaryTextColor,
                ),
                onSelected: (val) => setState(() => _priority = 'MEDIA'),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Prioritário (PCD, Gestante, 60+)'),
                selected: _priority == 'ALTA',
                selectedColor: Colors.amber.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _priority == 'ALTA' ? Colors.amber[800] : context.secondaryTextColor,
                ),
                onSelected: (val) => setState(() => _priority = 'ALTA'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Campo de Observação
          Text(
            'Descreva brevemente o assunto:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primaryTextColor),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: TextStyle(fontSize: 13, color: context.primaryTextColor),
            decoration: InputDecoration(
              hintText: 'Ex: Dúvida sobre validação de horas complementares ou boleto...',
              hintStyle: TextStyle(fontSize: 12, color: context.secondaryTextColor),
              fillColor: context.inputFillColor,
              filled: true,
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
                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botões de Ação
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Voltar', style: TextStyle(color: context.secondaryTextColor)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOpen ? AppColors.primaryGreen : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(isOpen ? Icons.check_rounded : Icons.lock_clock_rounded, size: 18),
                label: Text(
                  !isOpen
                      ? 'Atendimento Fechado no Momento'
                      : (_modality == 'PRESENCIAL' ? 'Retirar Senha Presencial' : 'Entrar na Fila Online'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: (!isOpen || _isSubmitting) ? null : _submitEscalation,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModalityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _modality == value;
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: () => setState(() => _modality = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryGreen.withValues(alpha: 0.15) : AppColors.accentMint.withValues(alpha: 0.5))
              : context.inputFillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGreen : context.secondaryTextColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primaryGreen : context.primaryTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketGeneratedView() {
    final ticket = _createdTicket!;
    final isPresencial = ticket.modality == 'PRESENCIAL';
    final ticketCode = ticket.ticketNumber ?? '#${ticket.id}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 56),
        const SizedBox(height: 12),
        Text(
          isPresencial ? 'Senha Gerada com Sucesso!' : 'Você entrou na Fila Online!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.primaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          isPresencial
              ? 'Aguarde ser chamado no painel do campus ou pelo app.'
              : 'Um atendente do ASA atenderá seu chamado em breve.',
          style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Ticket Card Estilizado
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.inputFillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGreen, width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                isPresencial ? 'SENHA DE ATENDIMENTO' : 'CHAMADO VIRTUAL',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticketCode,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPresencial ? '🏢 Atendimento Presencial - Balcão ASA' : '💬 Atendimento Remoto - Chat ASA',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
              ),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ticketMetric('Tempo estimado', '~10 min'),
                  _ticketMetric('Sua frente', '2 pessoas'),
                  _ticketMetric('Prioridade', ticket.priority == 'ALTA' ? 'Prioritária' : 'Geral'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido / Acompanhar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _ticketMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: context.secondaryTextColor)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primaryTextColor),
        ),
      ],
    );
  }

  Future<void> _submitEscalation() async {
    setState(() => _isSubmitting = true);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final notes = _notesController.text.trim();
    final result = await chatProvider.escalateToHuman(
      widget.defaultReason,
      userNotes: notes.isNotEmpty ? notes : null,
      modality: _modality,
      priority: _priority,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      setState(() => _createdTicket = result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa iniciar uma conversa antes de retirar uma senha.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
