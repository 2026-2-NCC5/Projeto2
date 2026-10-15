import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/core/responsive_breakpoints.dart';
import 'package:asa_connect/widgets/common/brand_header.dart';
import 'package:asa_connect/screens/auth/login_screen.dart';

class ProfileItem {
  final String key;
  final String title;
  final String description;
  final String imageAsset;
  final bool isFunctional;

  ProfileItem({
    required this.key,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.isFunctional = true,
  });
}

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<ProfileItem> _profiles = [
    ProfileItem(
      key: 'ALUNO',
      title: 'ALUNO',
      description: 'ENCONTRE RESPOSTAS, SERVIÇOS E ORIENTAÇÕES ACADÊMICAS.',
      imageAsset: 'assets/images/persona_aluna.png',
      isFunctional: true,
    ),
    ProfileItem(
      key: 'PROFESSOR',
      title: 'PROFESSOR',
      description: 'CONSULTE INFORMAÇÕES E PROCEDIMENTOS PARA APOIAR SUA ATIVIDADE ACADÊMICA.',
      imageAsset: 'assets/images/persona_professor.png',
      isFunctional: true,
    ),
    ProfileItem(
      key: 'RESPONSAVEL',
      title: 'RESPONSÁVEL',
      description: 'ENCONTRE INFORMAÇÕES E ORIENTAÇÕES SOBRE OS SERVIÇOS DA INSTITUIÇÃO.',
      imageAsset: 'assets/images/persona_atendente.png',
      isFunctional: true,
    ),
    ProfileItem(
      key: 'COLABORADOR',
      title: 'COLABORADOR',
      description: 'ACESSE INFORMAÇÕES E PROCEDIMENTOS INSTITUCIONAIS AUTORIZADOS.',
      imageAsset: 'assets/images/persona_coordenadora.png',
      isFunctional: true,
    ),
  ];

  void _onProfileSelected(ProfileItem profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(selectedProfile: profile.key),
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Desktop: show all 4 cards side-by-side ──────────────────────────────
    if (context.isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.headerGreen,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabeçalho da FECAP / ASA
                    const AsaLogo(width: 180, isDarkBackground: true),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SELECIONE SEU PERFIL INSTITUCIONAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Grid dos 4 Perfis em Cards Elegantes e Compactos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _profiles.map((item) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _onProfileSelected(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white30, width: 1),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 110,
                                        child: Image.asset(
                                          item.imageAsset,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.description,
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.3,
                                          color: Colors.white.withValues(alpha: 0.85),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'FECAP — Fundação Escola de Comércio Álvares Penteado',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── Mobile: original PageView carousel ──────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.headerGreen,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Título Superior (igual ProfileSelectionScreen.tsx)
            const Text(
              'ESCOLHA SEU PERFIL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: Colors.white,
              ),
            ),

            // Carrossel Central
            Expanded(
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.touch,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _profiles.length,
                  onPageChanged: (idx) {
                    setState(() => _currentPage = idx);
                  },
                  itemBuilder: (context, index) {
                    final item = _profiles[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _onProfileSelected(item),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Imagem clicável direta sem nenhuma moldura
                              SizedBox(
                                height: 250,
                                child: Image.asset(
                                  item.imageAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Nome do Perfil
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Descrição / Subtítulo
                              Text(
                                item.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Indicador de Bolinhas (Pagination Dots clicáveis)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _profiles.length,
                (index) => GestureDetector(
                  onTap: () => _goToPage(index),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.success : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
