// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Para SharedPreferencesKeys
// REMOVIDO: importação direta de FirebaseConstants
import 'package:runfit_app/screens/login_screen.dart'; // Importe a tela de login
import 'package:runfit_app/screens/main_screen.dart'; // Importe a tela principal (ainda usada para pushReplacement)
// REMOVIDO: importação de Firebase Realtime Database para esta tela

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // REMOVIDO: Controladores e variáveis de estado relacionados ao formulário de perfil
  // (nome, gênero, idade, altura, peso) foram movidos ou serão tratados após o registro/login.

  @override
  void initState() {
    super.initState();
    // A inicialização da referência do Firebase de perfil foi removida daqui.
    // Os dados do perfil serão salvos após o login/registro do usuário.
  }

  @override
  void dispose() {
    _pageController.dispose();
    // REMOVIDO: Dispose dos controladores do formulário de perfil.
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SharedPreferencesKeys.isOnboardingCompleted, true); // Marca o onboarding como concluído

    if (mounted) {
      // Após o onboarding, navegue para a tela de Login.
      // O usuário precisará criar uma conta ou fazer login.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()), // Leva para a LoginScreen
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> onboardingPages = [
      // Primeira página: Logo + Bem-vindo
      Stack(
        children: [
          _buildOnboardingBasePage(
            imagePath: 'assets/images/tela_inicio.png',
            blendMode: BlendMode.darken,
            blendColor: Colors.black.withOpacity(0.5),
            title: null,
            description: null,
          ),
          Center(
            child: Image.asset(
              'assets/images/logo_hibridus.png',
              height: 150,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Bem-vindo ao RunFit!',
                    style: AppStyles.titleTextStyle.copyWith(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Seu parceiro completo para uma vida ativa e saudável.',
                    style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Páginas de introdução de recursos
      _buildOnboardingBasePage(
        imagePath: 'assets/images/tela_corrida.png',
        title: 'Rastreie Suas Corridas',
        description: 'Acompanhe distância, tempo, ritmo e visualize seu percurso no mapa em tempo real.',
        blendMode: BlendMode.darken,
        blendColor: Colors.black.withOpacity(0.6),
      ),
      _buildOnboardingBasePage(
        imagePath: 'assets/images/tela_musculaçao.png',
        title: 'Gerencie Seus Treinos',
        description: 'Crie suas próprias fichas de treino ou use as prontas e registre cada exercício detalhadamente.',
        blendMode: BlendMode.darken,
        blendColor: Colors.black.withOpacity(0.6),
      ),
      _buildOnboardingBasePage(
        imagePath: 'assets/images/metas.png',
        title: 'Alcance Suas Metas e Conquistas',
        description: 'Defina objetivos personalizados, ganhe conquistas e mantenha-se motivado em sua jornada fitness.',
        blendMode: BlendMode.darken,
        blendColor: Colors.black.withOpacity(0.7),
      ),
      // Última página: Agora será um slide de "Pronto para começar?" que leva ao login/registro.
      _buildCallToActionPage(), // NOVO: Página final para chamar para login/registro
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingPages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return onboardingPages[index];
            },
          ),
          // Indicador de Dots
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingPages.length,
                    (index) => _buildDot(index),
              ),
            ),
          ),
          // Botões de Navegação
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage < onboardingPages.length - 1)
                  TextButton(
                    onPressed: () {
                      _pageController.jumpToPage(onboardingPages.length - 1);
                    },
                    child: Text('Pular', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.textSecondaryColor)),
                  ),
                if (_currentPage < onboardingPages.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                    },
                    style: AppStyles.buttonStyle,
                    child: Text('Próximo', style: AppStyles.buttonTextStyle),
                  )
                else // Na última página (chamada para ação)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _completeOnboarding,
                      style: AppStyles.buttonStyle,
                      child: Text('Começar', style: AppStyles.buttonTextStyle),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para construir as páginas de onboarding
  Widget _buildOnboardingBasePage({
    required String imagePath,
    String? title,
    String? description,
    BlendMode? blendMode,
    Color? blendColor,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: blendColor != null ? ColorFilter.mode(blendColor, blendMode ?? BlendMode.srcOver) : null,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title != null)
              Text(
                title,
                style: AppStyles.titleTextStyle.copyWith(fontSize: 32),
                textAlign: TextAlign.center,
              ),
            if (description != null) ... [
              const SizedBox(height: 20),
              Text(
                description,
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }

  // Helper para construir os indicadores de página
  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.accentColor : AppColors.textPrimaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // NOVA PÁGINA: Chamada para ação para Login/Registro
  Widget _buildCallToActionPage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/tela_inicio.png'), // Imagem de fundo similar
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Pronto para começar sua jornada fitness?',
              style: AppStyles.titleTextStyle.copyWith(fontSize: 32),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Crie sua conta ou faça login para começar a rastrear, planejar e alcançar seus objetivos!',
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }
}