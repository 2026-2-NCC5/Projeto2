import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/screens/chat/chat_screen.dart';
import 'package:asa_connect/screens/academic_services/service_detail_screen.dart';
import 'package:asa_connect/state/chat_provider.dart';

class DocumentsScreen extends StatefulWidget {
  final bool isTab;
  final String? initialCategory;

  const DocumentsScreen({super.key, this.isTab = false, this.initialCategory});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isUploading = false;
  String? _uploadSuccessMessage;

  final List<Map<String, String>> _recentFiles = [
    {
      'name': 'Histórico_Escolar_2023.2.pdf',
      'category': 'Acadêmico',
      'date': 'Ontem, 14:20',
      'size': '1.8 MB',
    },
    {
      'name': 'Atestado_Matricula_Atualizado.pdf',
      'category': 'Acadêmico',
      'date': '15 Out 2023',
      'size': '420 KB',
    },
    {
      'name': 'Boleto_Mensalidade_Nov.pdf',
      'category': 'Financeiro',
      'date': '10 Out 2023',
      'size': '850 KB',
    },
    {
      'name': 'Termo_Compromisso_Estagio.pdf',
      'category': 'Estágio',
      'date': '02 Out 2023',
      'size': '2.1 MB',
    },
  ];

  Future<void> _pickFile() async {
    try {
      setState(() => _isUploading = true);
      await Future.delayed(const Duration(milliseconds: 1300));
      setState(() {
        _isUploading = false;
        _uploadSuccessMessage = "Arquivo 'Comprovante_Matricula_2024.pdf' analisado com sucesso pela IA do ASA Connect!";
        _recentFiles.insert(0, {
          'name': 'Comprovante_Matricula_2024.pdf',
          'category': 'Análise AI',
          'date': 'Hoje, agora',
          'size': '1.2 MB',
        });
      });
      if (mounted) {
        _showAnalysisModal('Comprovante_Matricula_2024.pdf');
      }
    } catch (_) {
      setState(() => _isUploading = false);
    }
  }

  void _showAnalysisModal(String filename) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? AppColors.primaryGreen.withValues(alpha: 0.25) : AppColors.accentMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Análise Inteligente de Documento',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                      ),
                      Text(
                        'Processado pelo motor RAG do ASA Connect',
                        style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: context.primaryTextColor),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.inputFillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnalysisRow('Arquivo:', filename),
                  _buildAnalysisRow('Tipo Detectado:', 'Comprovante Oficial de Matrícula Regular'),
                  _buildAnalysisRow('Estudante:', 'Lucas Alvarista Silva (RA: 123456)'),
                  _buildAnalysisRow('Semestre Letivo:', '2024.1 - Ciência da Computação (5º Semestre)'),
                  _buildAnalysisRow('Autenticação Digital:', 'Chave SHA256 FECAP Verificada ✓'),
                  _buildAnalysisRow('Validade Jurídica:', 'Válido para estágio, passe escolar e benefícios.'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Tirar dúvidas com o ASA sobre este documento', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                  chatProvider.startNewChat();
                  chatProvider.sendMessage('Acabei de enviar o documento $filename. Gostaria de entender quais procedimentos e prazos acadêmicos oficiais posso realizar com ele na FECAP.');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.secondaryTextColor)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.primaryTextColor)),
          ),
        ],
      ),
    );
  }

  void _showAllDocumentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Todos os Documentos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: context.primaryTextColor),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _recentFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final file = _recentFiles[index];
                    return ListTile(
                      tileColor: context.inputFillColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.borderColor),
                      ),
                      leading: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.headerGreen,
                        size: 28,
                      ),
                      title: Text(
                        file['name']!,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.primaryTextColor),
                      ),
                      subtitle: Text(
                        '${file['category']} · ${file['date']} · ${file['size']}',
                        style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.download_rounded,
                          color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.headerGreen,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _downloadFile(file['name']!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadFile(String filename) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Download concluído: $filename salvo com sucesso.')),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _askAboutCategory(String category) {
    String query;
    if (category.contains('Acadêmico')) {
      query = 'Como emitir atestado de matrícula, histórico escolar ou outros documentos acadêmicos na FECAP?';
    } else if (category.contains('Financeiro')) {
      query = 'Como emitir 2ª via de boleto, comprovante de pagamento ou informe de rendimentos para Imposto de Renda na FECAP?';
    } else if (category.contains('Estágio') || category.contains('TCE')) {
      query = 'Quais são as regras, prazos e como validar o Termo de Compromisso de Estágio (TCE) e relatórios na FECAP?';
    } else {
      query = 'Como abrir e acompanhar requerimentos e protocolos de processos acadêmicos na FECAP?';
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startNewChat();
    chatProvider.sendMessage(query);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção Categorias (Figma tela 6)
          Text(
            'Categorias',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.primaryTextColor),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              _buildCategoryCard(
                icon: Icons.description_outlined,
                title: 'ACADÊMICOS',
                subtitle: 'Histórico, Atestados',
                onTap: () => _askAboutCategory('Acadêmicos'),
              ),
              _buildCategoryCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'FINANCEIROS',
                subtitle: 'Boletos, IR',
                onTap: () => _askAboutCategory('Financeiros'),
              ),
              _buildCategoryCard(
                icon: Icons.business_center_outlined,
                title: 'ESTÁGIO',
                subtitle: 'Contratos, Relatórios',
                onTap: () => _askAboutCategory('Estágio e TCE'),
              ),
              _buildCategoryCard(
                icon: Icons.folder_open_outlined,
                title: 'OUTROS',
                subtitle: 'Formulários gerais',
                onTap: () => _askAboutCategory('Requerimentos Gerais'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Seção "Enviar para Análise AI"
          Row(
            children: [
              Text(
                'Enviar para Análise AI',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.primaryTextColor),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? AppColors.primaryGreen.withValues(alpha: 0.25) : AppColors.accentMint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'IA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? AppColors.primaryGreen.withValues(alpha: 0.25) : AppColors.accentMint,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Selecione ou arraste um arquivo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF, DOCX ou JPG até 10MB',
                  style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
                ),
                const SizedBox(height: 16),

                if (_uploadSuccessMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? AppColors.primaryGreen.withValues(alpha: 0.25) : AppColors.accentMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _uploadSuccessMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: _isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.file_upload_outlined, size: 16),
                  label: Text(_isUploading ? 'Processando...' : 'Escolher Arquivo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção "Recentes"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recentes',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.primaryTextColor),
              ),
              TextButton(
                onPressed: _showAllDocumentsModal,
                child: const Text('VER TODOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentFiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final file = _recentFiles[index];
              return Material(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailScreen(
                          serviceTitle: file['name']!,
                          documentSlug: 'documentos_oficiais',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? AppColors.primaryGreen.withValues(alpha: 0.25)
                                : AppColors.headerGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.headerGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file['name']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.primaryTextColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${file['category']} • ${file['date']} • ${file['size']}',
                                style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.download_rounded,
                            color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.headerGreen,
                            size: 20,
                          ),
                          tooltip: 'Baixar Documento',
                          onPressed: () => _downloadFile(file['name']!),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    if (widget.isTab) return body;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.headerColor,
        title: const Text('Documentos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (val) {
              if (val == 'all') {
                _showAllDocumentsModal();
              } else if (val == 'refresh') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lista de documentos atualizada.'), backgroundColor: AppColors.success),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Ver Todos os Documentos')),
              const PopupMenuItem(value: 'refresh', child: Text('Atualizar Lista')),
            ],
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xFF281F40) : AppColors.aiPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: context.isDarkMode ? const Color(0xFFB49BFF) : AppColors.aiPurple, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: context.secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
