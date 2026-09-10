import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asa_connect/core/constants.dart';
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
      imageAsset: 'assets/images/persona_aluno.png',
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
