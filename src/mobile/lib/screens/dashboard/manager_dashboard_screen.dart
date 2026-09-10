import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/services/api_client.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _client = ApiClient();

  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _escalations = [];
  List<dynamic> _documents = [];
  List<dynamic> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final statsResp = await _client.get('/dashboard/stats');
      final escResp = await _client.get('/escalations');
      final docsResp = await _client.get('/documents?active_only=false');
      final logsResp = await _client.get('/dashboard/audit-logs?limit=15');

      if (statsResp.statusCode == 200) {
        _stats = jsonDecode(utf8.decode(statsResp.bodyBytes));
      }
      if (escResp.statusCode == 200) {
        _escalations = jsonDecode(utf8.decode(escResp.bodyBytes));
      }
      if (docsResp.statusCode == 200) {
        _documents = jsonDecode(utf8.decode(docsResp.bodyBytes));
      }
      if (logsResp.statusCode == 200) {
        _auditLogs = jsonDecode(utf8.decode(logsResp.bodyBytes));
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados gerenciais: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _resolveEscalation(int caseId) async {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolver Caso de Atendimento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informe a orientação ou justificativa fornecida ao estudante (RF08):',
              style: TextStyle(fontSize: 12, color: AppColors.textBody),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ex: Orientado a comparecer na Secretaria Geral para retirada do documento oficial com RG...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () async {
              final text = notesController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A justificativa é obrigatória para encerrar o caso.')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              try {
                final resp = await _client.patch('/escalations/$caseId/resolve', {
                  'status': 'RESOLVIDO',
                  'resolution_notes': text,
                });
                if (resp.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caso resolvido com sucesso!'), backgroundColor: AppColors.success),
                  );
                  _loadDashboardData();
                }
              } catch (_) {}
            },
            child: const Text('Confirmar Resolução'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDocumentActive(int docId, bool currentStatus) async {
    try {
      final resp = await _client.patch('/documents/$docId/toggle-active', {
        'is_active': !currentStatus,
      });
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? 'Documento ativado na base RAG.' : 'Documento desativado do índice RAG.'),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadDashboardData();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.headerGreen,
        title: const Text('Painel Gerencial ASA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar Dados',
            onPressed: _loadDashboardData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.success,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.insights_rounded, size: 18), text: 'Métricas RAG'),
            Tab(icon: Icon(Icons.support_agent_rounded, size: 18), text: 'Fila Humana'),
            Tab(icon: Icon(Icons.source_rounded, size: 18), text: 'Base RAG'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMetricsTab(),
                _buildEscalationsTab(),
                _buildKnowledgeBaseTab(),
              ],
            ),
    );
  }

  Widget _buildMetricsTab() {
    if (_stats == null) {
      return const Center(child: Text('Sem métricas disponíveis.'));
    }

    final abstentionRate = (_stats!['abstention_rate'] as num).toDouble();
    final satisfactionRate = (_stats!['feedback']['satisfaction_rate'] as num).toDouble();
    final categories = (_stats!['top_categories'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Indicadores de Qualidade e Operação (RF11)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 12),

          // Grid de 4 KPIs
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _buildKpiCard(
                title: 'TOTAL DE CONVERSAS',
                value: '${_stats!['total_conversations']}',
                subtitle: '${_stats!['total_messages']} mensagens processadas',
                icon: Icons.chat_rounded,
                color: AppColors.primaryGreen,
              ),
              _buildKpiCard(
                title: 'TAXA DE ABSTENÇÃO',
                value: '$abstentionRate%',
                subtitle: '${_stats!['total_abstentions']} abstenções seguras',
                icon: Icons.shield_outlined,
                color: abstentionRate > 30 ? AppColors.abstentionAmber : AppColors.accentEmerald,
              ),
              _buildKpiCard(
                title: 'ÍNDICE DE SATISFAÇÃO',
                value: '$satisfactionRate%',
                subtitle: '${_stats!['feedback']['helpful_count']} úteis / ${_stats!['feedback']['unhelpful_count']} não úteis',
                icon: Icons.thumb_up_alt_outlined,
                color: AppColors.accentEmerald,
              ),
              _buildKpiCard(
                title: 'FILA DE ATENDIMENTO',
                value: '${_stats!['pending_escalations']}',
                subtitle: '${_stats!['resolved_escalations']} casos resolvidos',
                icon: Icons.people_outline_rounded,
                color: _stats!['pending_escalations'] > 0 ? AppColors.error : AppColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tópicos Mais Frequentes
          const Text('Distribuição por Categorias da Base', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: categories.map((cat) {
                final pct = (cat['percentage'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat['category'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$pct% (${cat['count']} docs)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Log de Auditoria Recente (RF10)
          const Text('Trilha de Auditoria Recente (RF10)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _auditLogs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final log = _auditLogs[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.history_toggle_off_rounded, size: 14, color: AppColors.primaryGreen),
                  ),
                  title: Text(log['action'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text('Usuário: ${log['user_name']} · ${log['created_at'].toString().substring(11, 16)}', style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEscalationsTab() {
    if (_escalations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all_rounded, size: 48, color: Colors.green.shade300),
            const SizedBox(height: 12),
            const Text('Nenhum caso pendente na fila humana do ASA.', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _escalations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final esc = _escalations[index];
        final isResolved = esc['status'] == 'RESOLVIDO';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isResolved ? AppColors.borderLight : const Color(0xFFFCA5A5),
              width: isResolved ? 1.0 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isResolved ? AppColors.accentMint : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      esc['status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isResolved ? AppColors.primaryGreen : AppColors.error,
                      ),
                    ),
                  ),
                  Text('Prioridade: ${esc['priority']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 10),

              Text(
                'Estudante: ${esc['student_name']} (RA: ${esc['student_ra'] ?? "N/A"})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text('Motivo: ${esc['reason']}', style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
              if (esc['user_notes'] != null) ...[
                const SizedBox(height: 4),
                Text('Dúvida: "${esc['user_notes']}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
              ],

              if (isResolved && esc['resolution_notes'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Justificativa: ${esc['resolution_notes']}', style: const TextStyle(fontSize: 11, color: AppColors.textBody)),
                ),
              ],

              if (!isResolved) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Atender / Resolver Caso', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _resolveEscalation(esc['id']),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildKnowledgeBaseTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final doc = _documents[index];
        final isActive = doc['is_active'] == true;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accentMint : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: isActive ? AppColors.primaryGreen : AppColors.textLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['title'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.textDark : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc['category']} · ${doc['official_source']}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                activeColor: AppColors.primaryGreen,
                onChanged: (_) => _toggleDocumentActive(doc['id'], isActive),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textMuted)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
