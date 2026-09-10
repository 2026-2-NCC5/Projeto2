import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/theme.dart';
import 'package:asa_connect/services/api_client.dart';
import 'package:asa_connect/state/accessibility_provider.dart';
import 'package:asa_connect/state/auth_provider.dart';
import 'package:asa_connect/state/chat_provider.dart';
import 'package:asa_connect/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa serviços e provedores locais
  final apiClient = ApiClient();
  await apiClient.init();

  final accessibilityProvider = AccessibilityProvider();
  await accessibilityProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => accessibilityProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const AsaConnectApp(),
    ),
  );
}

class AsaConnectApp extends StatelessWidget {
  const AsaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibility, _) {
        return MaterialApp(
          title: 'ASA Connect+',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(
            fontScale: accessibility.fontScaleFactor,
            highContrast: accessibility.highContrast,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
