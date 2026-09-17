import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/widgets/common/brand_header.dart';
import 'package:asa_connect/state/auth_provider.dart';
import 'package:asa_connect/screens/auth/recovery_screen.dart';
import 'package:asa_connect/screens/home/home_screen.dart';
import 'package:asa_connect/screens/profile_selection/profile_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  final String selectedProfile;

  const LoginScreen({super.key, this.selectedProfile = 'ALUNO'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _identifierController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    String defaultId = '123456';
    String defaultPwd = 'senha123';

    if (widget.selectedProfile == 'PROFESSOR') {
      defaultId = 'prof.almeida@fecap.br';
    } else if (widget.selectedProfile == 'ATENDENTE' || widget.selectedProfile == 'ATENDENTE_ASA') {
      defaultId = 'atendente@fecap.br';
    } else if (widget.selectedProfile == 'COLABORADOR' || widget.selectedProfile == 'ADMINISTRADOR') {
      defaultId = 'admin@fecap.br';
    } else if (widget.selectedProfile == 'RESPONSAVEL') {
      defaultId = 'responsavel@fecap.br';
    }

    _identifierController = TextEditingController(text: defaultId);
    _passwordController = TextEditingController(text: defaultPwd);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillCredentials(String id, String pwd) {
    setState(() {
      _identifierController.text = id;
      _passwordController.text = pwd;
    });
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
      );
    }
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.headset_mic_rounded, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text('Canais de Atendimento ASA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Problemas para acessar o aplicativo ou recuperar suas credenciais?',
              style: TextStyle(fontSize: 12, color: context.secondaryTextColor, height: 1.4),
            ),
            const SizedBox(height: 14),
            _buildSupportItem(Icons.chat_bubble_outline_rounded, 'WhatsApp Oficial:', '(11) 3272-2222'),
            _buildSupportItem(Icons.email_outlined, 'E-mail:', 'asa@fecap.br'),
            _buildSupportItem(Icons.access_time_rounded, 'Horário:', 'Seg a Sex das 08h às 21h'),
            _buildSupportItem(Icons.location_on_outlined, 'Local:', 'Campus Liberdade – Bloco A (Térreo)'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: context.primaryTextColor),
                children: [
                  TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value, style: TextStyle(color: context.secondaryTextColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Erro ao autenticar.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.headerGreen,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                // Botão Voltar ao Perfil Selecionado com navegação segura
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _handleBack,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.selectedProfile.toLowerCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              const AsaLogo(width: 200, isDarkBackground: true),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: context.isDarkMode ? Colors.black45 : Colors.black26,
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Acesso Institucional',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'RA / MATRICULA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: context.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _identifierController,
                        keyboardType: TextInputType.text,
                        style: TextStyle(color: context.primaryTextColor),
                        decoration: InputDecoration(
                          hintText: 'Digite seu RA ou e-mail',
                          hintStyle: TextStyle(color: context.secondaryTextColor),
                          prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.primaryGreen),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Informe seu RA ou e-mail' : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SENHA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: context.secondaryTextColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RecoveryScreen()),
                              );
                            },
                            child: const Text(
                              'Esqueci minha senha',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: context.primaryTextColor),
                        decoration: InputDecoration(
                          hintText: 'Senha',
                          hintStyle: TextStyle(color: context.secondaryTextColor),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primaryGreen),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: context.secondaryTextColor,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe sua senha' : null,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _submitLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Entrar',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          'Contas de Teste para Avaliação:',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.secondaryTextColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          ActionChip(
                            label: Text('Aluno 123456', style: TextStyle(fontSize: 10, color: context.primaryTextColor)),
                            backgroundColor: context.isDarkMode ? AppDarkColors.surfaceInput : const Color(0xFFF1F5F9),
                            side: BorderSide(color: context.borderColor),
                            onPressed: () => _fillCredentials('123456', 'senha123'),
                          ),
                          ActionChip(
                            label: Text('Prof. Almeida', style: TextStyle(fontSize: 10, color: context.primaryTextColor)),
                            backgroundColor: context.isDarkMode ? AppDarkColors.surfaceInput : const Color(0xFFF1F5F9),
                            side: BorderSide(color: context.borderColor),
                            onPressed: () => _fillCredentials('prof.almeida@fecap.br', 'senha123'),
                          ),
                          ActionChip(
                            label: Text('Atendente ASA', style: TextStyle(fontSize: 10, color: context.primaryTextColor)),
                            backgroundColor: context.isDarkMode ? AppDarkColors.surfaceInput : const Color(0xFFF1F5F9),
                            side: BorderSide(color: context.borderColor),
                            onPressed: () => _fillCredentials('atendente@fecap.br', 'senha123'),
                          ),
                          ActionChip(
                            label: Text('Admin', style: TextStyle(fontSize: 10, color: context.primaryTextColor)),
                            backgroundColor: context.isDarkMode ? AppDarkColors.surfaceInput : const Color(0xFFF1F5F9),
                            side: BorderSide(color: context.borderColor),
                            onPressed: () => _fillCredentials('admin@fecap.br', 'senha123'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: context.borderColor),
                      const SizedBox(height: 12),

                      Center(
                        child: TextButton(
                          onPressed: _showSupportDialog,
                          child: Text(
                            'Problemas com o acesso? Fale com o Suporte',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                AppConstants.institutionName,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
