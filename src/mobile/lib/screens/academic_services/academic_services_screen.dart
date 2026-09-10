import 'package:flutter/material.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/screens/academic_services/service_detail_screen.dart';

class AcademicServicesScreen extends StatelessWidget {
  final bool isTab;

  const AcademicServicesScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtítulo do Topo
          const Text(
            'Selecione uma categoria abaixo para acessar os serviços disponíveis para o seu perfil de Aluno.',
            style: TextStyle(fontSize: 12, color: AppColors.textBody, height: 1.4),
          ),
          const SizedBox(height: 16),

            // 1. Matrícula
            _buildServiceGroup(
              context,
              icon: Icons.app_registration_rounded,
              categoryTitle: 'Matrícula',
              items: [
                _ServiceItem(
                  title: 'Renovação de Matrícula',
                  slug: 'rematricula_prazos_regras',
                  badge: null,
                ),
                _ServiceItem(
                  title: 'Trancamento de Curso',
                  slug: 'trancamento_disciplinas',
                  badge: null,
                ),
                _ServiceItem(
                  title: 'Inclusão/Exclusão de Disciplinas',
                  slug: 'trancamento_disciplinas',
                  badge: null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Histórico & Documentos
            _buildServiceGroup(
              context,
              icon: Icons.history_edu_rounded,
              categoryTitle: 'Histórico & Documentos',
              items: [
                _ServiceItem(
                  title: 'Atestado de Matrícula',
                  slug: 'atestado_matricula',
                  badge: 'Oficial',
                ),
                _ServiceItem(
                  title: 'Emitir Histórico Escolar',
                  slug: 'atestado_matricula',
                  badge: null,
                ),
                _ServiceItem(
                  title: 'Boletim de Notas',
                  slug: 'atestado_matricula',
                  badge: 'Oficial',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Diploma & Conclusão
            _buildServiceGroup(
              context,
              icon: Icons.school_rounded,
              categoryTitle: 'Diploma',
              items: [
                _ServiceItem(
                  title: 'Solicitação de Diploma',
                  slug: 'solicitacao_diploma',
                  badge: null,
                ),
                _ServiceItem(
                  title: 'Certificado de Conclusão',
                  slug: 'solicitacao_diploma',
                  badge: null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Atividades Complementares
            _buildServiceGroup(
              context,
              icon: Icons.military_tech_outlined,
              categoryTitle: 'Atividades Complementares',
              items: [
                _ServiceItem(
                  title: 'Envio de Certificados (AAC)',
                  slug: 'atividades_complementares',
                  badge: null,
                ),
                _ServiceItem(
                  title: 'Consulta de Horas Computadas',
                  slug: 'atividades_complementares',
                  badge: null,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      );

    if (isTab) {
      return Container(
        color: AppColors.background,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.headerGreen,
        title: const Text('Serviços Acadêmicos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: content,
    );
  }

  Widget _buildServiceGroup(
    BuildContext context, {
    required IconData icon,
    required String categoryTitle,
    required List<_ServiceItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Categoria
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  categoryTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Lista de Itens
          ...items.map((item) {
            return ListTile(
              title: Text(
                item.title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textBody),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentMint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.badge!,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailScreen(
                      serviceTitle: item.title,
                      documentSlug: item.slug,
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String slug;
  final String? badge;

  _ServiceItem({required this.title, required this.slug, this.badge});
}
