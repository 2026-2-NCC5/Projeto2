import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/state/chat_provider.dart';
import 'package:asa_connect/screens/chat/chat_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceTitle;
  final String documentSlug;

  const ServiceDetailScreen({
    super.key,
    required this.serviceTitle,
    required this.documentSlug,
  });

  void _askAssistant(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startNewChat();
    chatProvider.sendMessage("Gostaria de tirar dúvidas sobre o procedimento de: $serviceTitle");
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.headerGreen,
        elevation: 0,
        title: Text(serviceTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges de Autenticidade (Figma tela 12)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.business_outlined, size: 12, color: AppColors.textDark),
                            SizedBox(width: 4),
                            Text('Secretaria Geral', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentMint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 12, color: AppColors.primaryGreen),
                            SizedBox(width: 4),
                            Text('Fonte Oficial', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Título e Descrição Principal
                  Text(
                    serviceTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Documento institucional oficial que comprova o vínculo e procedimentos ativos do aluno no semestre letivo vigente.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Seção Sobre
                  _buildSectionTitle('Sobre o Procedimento'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Text(
                      'Este serviço é regulamentado pela Secretaria Geral e Diretoria Acadêmica da FECAP. Possui validação digital com QR Code verificador e assinatura eletrônica institucional, dispensando carimbos manuais ou assinaturas físicas para fins legais e comprobatórios.',
                      style: TextStyle(fontSize: 12, color: AppColors.textBody, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Seção Passo a Passo Numerado
                  _buildSectionTitle('Como Solicitar (Passo a Passo)'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _buildStepItem(1, 'Acesso ao Portal', 'Faça login no Portal do Aluno com seu RA e senha cadastrados.'),
                        const SizedBox(height: 12),
                        _buildStepItem(2, 'Navegação', 'Acesse o menu "Secretaria" no painel lateral e selecione "Emissão de Documentos".'),
                        const SizedBox(height: 12),
                        _buildStepItem(3, 'Confirmação & Download', 'Localize o item correspondente e clique em "Gerar PDF" para download imediato e gratuito.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Seção Requisitos
                  _buildSectionTitle('Requisitos Obrigatórios'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _buildRequirementItem('Estar regularmente matriculado no semestre letivo atual.'),
                        const SizedBox(height: 8),
                        _buildRequirementItem('Não possuir pendências de documentação civil básica na Secretaria.'),
                        const SizedBox(height: 8),
                        _buildRequirementItem('Sem impedimentos administrativos ou regimentais.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Citação da Fonte Oficial no Rodapé
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.menu_book_rounded, color: AppColors.primaryGreen, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Manual do Aluno 2024 · Capítulo 4 – Emissão de Documentos e Regulamento Institucional',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textLight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Botão Fixo no Rodapé: "Perguntar ao ASA Connect" (Design AI Studio)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3EEFF),
                    foregroundColor: AppColors.aiPurple,
                    elevation: 0,
                    side: BorderSide(color: AppColors.aiPurple.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.aiPurple),
                  label: const Text(
                    'Perguntar ao ASA Connect',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.aiPurple),
                  ),
                  onPressed: () => _askAssistant(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildStepItem(int number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.accentMint,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textBody, height: 1.3)),
        ),
      ],
    );
  }
}
