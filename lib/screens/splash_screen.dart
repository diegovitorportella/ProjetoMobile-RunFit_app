// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/screens/onboarding_screen.dart';
import 'package:runfit_app/screens/main_screen.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simula um tempo de carregamento mínimo para que a splash screen seja visível
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final bool isOnboardingCompleted =
        prefs.getBool(SharedPreferencesKeys.isOnboardingCompleted) ?? false;

    if (!mounted) return; // Verifica se o widget ainda está montado

    if (isOnboardingCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // Se o onboarding não foi concluído, direcione para a OnboardingScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remova o backgroundColor do Scaffold, pois o Stack vai cuidar do fundo
      body: Stack(
        fit: StackFit.expand, // Faz o Stack ocupar toda a tela
        children: [
          // 1. Imagem de Fundo
          Image.asset(
            'assets/images/tela_inicio.png', // Seu caminho para a imagem de fundo
            fit: BoxFit.cover, // Cobrirá toda a área disponível
            // Optional: Adicionar um ColorFilter para garantir que o texto seja legível
            // colorBlendMode: BlendMode.darken,
            // color: Colors.black.withOpacity(0.5), // Ajuste a opacidade conforme a imagem já escurecida
          ),

          // 2. Conteúdo da Splash Screen (Logo, Texto, Indicador de Progresso)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Seu logo atual
                Image.asset(
                  'assets/images/logo_hibridus.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 20),
                Text(
                  'RunFit',
                  style: AppStyles.titleTextStyle,
                ),
                const SizedBox(height: 10),
                Text(
                  'Seu Parceiro de Treino',
                  style: AppStyles.bodyStyle
                      .copyWith(color: AppColors.textSecondaryColor),
                ),
                const SizedBox(height: 40),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}