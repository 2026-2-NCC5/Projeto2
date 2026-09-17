import 'package:flutter/material.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/screens/academic_services/service_detail_screen.dart';

class AcademicServicesScreen extends StatefulWidget {
  final bool isTab;
  final String? filterCategory;

  const AcademicServicesScreen({super.key, this.isTab = false, this.filterCategory});

  @override
  State<AcademicServicesScreen> createState() => _AcademicServicesScreenState();
}

class _AcademicServicesScreenState extends State<AcademicServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.filterCategory ?? 'Todos';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Todos', 'Matrícula', 'Requerimentos', 'Documentos', 'Diploma', 'Financeiro', 'AAC'];

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de busca de serviços
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.inputFillColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: context.primaryTextColor, fontSize: 13),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar serviço ou procedimento...',
                      hintStyle: TextStyle(color: context.secondaryTextColor, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear_rounded, size: 18, color: context.secondaryTextColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Chips de categorias
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: context.cardColor,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : context.primaryTextColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppColors.primaryGreen : context.borderColor),
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Grupos de Serviços Filtrados
          if (_matchesCategory('Matrícula'))
            _buildServiceGroup(
              context,
              icon: Icons.app_registration_rounded,
              categoryTitle: 'Matrícula',
              items: [
                _ServiceItem(
                  title: 'Renovação de Matrícula',
                  slug: 'rematricula_prazos_regras',
                  badge: 'Essencial',
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

          if (_matchesCategory('Requerimentos')) ...[
            const SizedBox(height: 16),
            _buildServiceGroup(
              context,
              icon: Icons.assignment_outlined,
              categoryTitle: 'Requerimentos Gerais',
              items: [
                _ServiceItem(
                  title: 'Revisão de Notas e Faltas',
                  slug: 'revisao_notas_faltas',
                  badge: null,
                ),
                _ServiceItem(
                  title: 'Aproveitamento de Estudos / Dispensa',
                  slug: 'dispensa_disciplinas',
                  badge: null,
                ),
                _ServiceItem(
                  title: 'Mudança de Curso ou Turno',
                  slug: 'transferencia_interna_mudanca_curso',
                  badge: null,
                ),
              ],
            ),
          ],

          if (_matchesCategory('Documentos')) ...[
            const SizedBox(height: 16),
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
                  slug: 'historico_escolar_emissao',
                  badge: null,
                ),
                _ServiceItem(
                  title: 'Boletim de Notas',
                  slug: 'boletim_notas',
                  badge: 'Oficial',
                ),
              ],
            ),
          ],

          if (_matchesCategory('Financeiro')) ...[
            const SizedBox(height: 16),
            _buildServiceGroup(
              context,
              icon: Icons.account_balance_wallet_outlined,
              categoryTitle: 'Financeiro',
              items: [
                _ServiceItem(
                  title: '2ª Via de Boleto Bancário',
                  slug: 'servico_segunda_via_de_boleto_bancario',
                  badge: 'Rápido',
                ),
                _ServiceItem(
                  title: 'Acordo e Negociação de Mensalidades',
                  slug: 'servico_acordo_financeiro',
                  badge: null,
                ),
                _ServiceItem(
                  title: 'Informe de Rendimentos para IR',
                  slug: 'servico_informe_de_rendimentos',
                  badge: null,
                ),
              ],
            ),
          ],

          if (_matchesCategory('Diploma')) ...[
            const SizedBox(height: 16),
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
          ],

          if (_matchesCategory('AAC')) ...[
            const SizedBox(height: 16),
            _buildServiceGroup(
              context,
              icon: Icons.military_tech_outlined,
              categoryTitle: 'Atividades Complementares (AAC)',
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
          ],

          const SizedBox(height: 24),
        ],
      ),
    );

    if (widget.isTab) {
      return Container(
        color: context.backgroundColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.headerColor,
        title: const Text('Serviços Acadêmicos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: content,
    );
  }

  bool _matchesCategory(String cat) {
    if (_selectedCategory == 'Todos') return true;
    if (_selectedCategory == cat) return true;
    return false;
  }

  Widget _buildServiceGroup(
    BuildContext context, {
    required IconData icon,
    required String categoryTitle,
    required List<_ServiceItem> items,
  }) {
    final filteredItems = items.where((i) {
      if (_searchQuery.isEmpty) return true;
      return i.title.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredItems.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderColor),

          // Lista de Itens
          ...filteredItems.map((item) {
            return ListTile(
              title: Text(
                item.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryTextColor),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? AppColors.primaryGreen.withValues(alpha: 0.25) : AppColors.accentMint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.badge!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  Icon(Icons.chevron_right_rounded, color: context.secondaryTextColor, size: 20),
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
