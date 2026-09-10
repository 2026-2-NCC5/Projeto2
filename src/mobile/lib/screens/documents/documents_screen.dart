import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/screens/chat/chat_screen.dart';
import 'package:asa_connect/screens/academic_services/service_detail_screen.dart';
import 'package:asa_connect/state/chat_provider.dart';

class DocumentsScreen extends StatefulWidget {
  final bool isTab;

  const DocumentsScreen({super.key, this.isTab = false});

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
      // Simulação de upload de arquivo ou uso de file_picker
      await Future.delayed(const Duration(milliseconds: 1200));
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
    } catch (_) {
      setState(() => _isUploading = false);
    }
  }

  void _askAboutCategory(String category) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startNewChat();
    chatProvider.sendMessage("Quais documentos e procedimentos oficiais existem na categoria $category?");
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
          const Text(
            'Categorias',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
              const Text(
                'Enviar para Análise AI',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentMint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'IA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.accentMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.cloud_upload_outlined, color: AppColors.primaryGreen, size: 24),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Selecione ou arraste um arquivo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PDF, DOCX ou JPG até 10MB',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),

                if (_uploadSuccessMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _uploadSuccessMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
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
              const Text(
                'Recentes',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              TextButton(
                onPressed: () {},
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
                color: Colors.white,
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
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.headerGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.headerGreen, size: 20),
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
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${file['category']} • ${file['date']} • ${file['size']}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download_rounded, color: AppColors.headerGreen, size: 20),
                          tooltip: 'Baixar Documento',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Download de ${file['name']} iniciado.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.headerGreen,
        title: const Text('Documentos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.aiPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.aiPurple, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
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
