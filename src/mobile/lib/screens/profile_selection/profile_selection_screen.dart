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
      description: 'CONSULTE NORMAS DOCENTES, SINALIZAÇÕES PREVENTIVAS E APOIO AO ALUNO.',
      imageAsset: 'assets/images/persona_professor.png',
      isFunctional: true,
    ),
    ProfileItem(
      key: 'TIME_ASA',
      title: 'TIME ASA',
      description: 'ATENDIMENTO HUMANO, GESTÃO DE FILA E SUPORTE INSTITUCIONAL.',
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
            const SizedBox(height: 28),
            // Título Superior com tracking Apple
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'SELECIONE SEU ACESSO INSTITUCIONAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
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
                              // Imagem original da persona em tamanho de destaque
                              SizedBox(
                                height: 260,
                                child: Image.asset(
                                  item.imageAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Nome do Perfil
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Descrição / Subtítulo
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  item.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Botão Pílula Acessar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Entrar como ${item.title}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.headerGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: AppColors.headerGreen,
                                    ),
                                  ],
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
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
