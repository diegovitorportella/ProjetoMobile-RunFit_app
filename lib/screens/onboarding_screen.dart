// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart';
import 'package:runfit_app/screens/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controladores do formulário de perfil (mantidos aqui por simplicidade no onboarding)
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(SharedPreferencesKeys.isOnboardingCompleted, true);
      await prefs.setString(SharedPreferencesKeys.userName, _nameController.text);
      await prefs.setString(SharedPreferencesKeys.userGender, _selectedGender!);
      await prefs.setInt(SharedPreferencesKeys.userAge, int.parse(_ageController.text));
      await prefs.setDouble(SharedPreferencesKeys.userHeight, double.parse(_heightController.text));
      await prefs.setDouble(SharedPreferencesKeys.userWeight, double.parse(_weightController.text));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> onboardingPages = [
      // Primeira página: Logo + Bem-vindo
      Stack(
        children: [
          _buildOnboardingBasePage( // Imagem de fundo
            imagePath: 'assets/images/tela_inicio.png',
            blendMode: BlendMode.darken,
            blendColor: Colors.black.withOpacity(0.5),
            title: null, // Não exibir título e descrição da base aqui, pois são sobrepostos
            description: null,
          ),
          Center(
            child: Image.asset(
              'assets/images/logo_hibridus.png', // Caminho para o arquivo da sua logo
              height: 150, // Ajuste a altura conforme necessário
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
                  const SizedBox(height: 100), // Espaço para os botões e dots
                ],
              ),
            ),
          ),
        ],
      ),
      // Páginas de introdução de recursos
      _buildOnboardingBasePage(
        imagePath: 'assets/images/tela_corrida.png', // Imagem de fundo
        title: 'Rastreie Suas Corridas',
        description: 'Acompanhe distância, tempo, ritmo e visualize seu percurso no mapa em tempo real.',
        blendMode: BlendMode.darken,
        blendColor: Colors.black.withOpacity(0.6),
      ),
      _buildOnboardingBasePage(
        imagePath: 'assets/images/tela_musculaçao.png', // Imagem de fundo
        title: 'Gerencie Seus Treinos',
        description: 'Crie suas próprias fichas de treino ou use as prontas e registre cada exercício detalhadamente.',
        blendMode: BlendMode.darken,
        blendColor: Colors.black.withOpacity(0.6),
      ),
      _buildOnboardingBasePage(
        imagePath: 'assets/images/metas.png', // NOVA IMAGEM DE FUNDO
        title: 'Alcance Suas Metas e Conquistas',
        description: 'Defina objetivos personalizados, ganhe conquistas e mantenha-se motivado em sua jornada fitness.',
        blendMode: BlendMode.darken,
        blendColor: Colors.black.withOpacity(0.7), // Pode ajustar a opacidade se a imagem precisar
      ),
      // Última página: Formulário de Perfil
      _buildProfileFormPage(),
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
                if (_currentPage < onboardingPages.length - 1) // Se não for a última página (formulário)
                  TextButton(
                    onPressed: () {
                      _pageController.jumpToPage(onboardingPages.length - 1); // Pular para o formulário
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
                else // Na última página (formulário)
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

  // Helper para construir as páginas de onboarding (agora com width e height para preencher)
  Widget _buildOnboardingBasePage({
    required String imagePath,
    String? title,
    String? description,
    BlendMode? blendMode,
    Color? blendColor,
  }) {
    return Container(
      width: double.infinity,  // Garante que ocupa toda a largura disponível
      height: double.infinity, // Garante que ocupa toda a altura disponível
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover, // Preenche toda a área, cortando se necessário para manter a proporção
          colorFilter: blendColor != null ? ColorFilter.mode(blendColor, blendMode ?? BlendMode.srcOver) : null, // Aplica o escurecimento
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, // Alinha o conteúdo na parte inferior
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title != null) // Só exibe título e descrição se forem fornecidos
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
            const SizedBox(height: 150), // Espaço para os botões e dots
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

  // A página do formulário de perfil
  Widget _buildProfileFormPage() {
    return SingleChildScrollView( // Usar SingleChildScrollView para evitar overflow no formulário
      padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 100.0), // Ajustar padding para botões de navegação
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Nos conte um pouco sobre você para começarmos!',
              style: AppStyles.headingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _nameController,
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
              decoration: const InputDecoration(
                hintText: 'Digite seu nome',
                labelText: 'Nome',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, digite seu nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gênero',
              ),
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
              dropdownColor: AppColors.cardColor,
              items: UserGender.values.map((UserGender gender) {
                String formattedName = '';
                if (gender == UserGender.masculino) formattedName = 'Masculino';
                if (gender == UserGender.feminino) formattedName = 'Feminino';
                if (gender == UserGender.naoInformar) formattedName = 'Não Informar';
                return DropdownMenuItem<String>(
                  value: gender.name,
                  child: Text(formattedName, style: AppStyles.bodyStyle),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione seu gênero';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
              decoration: const InputDecoration(
                hintText: 'Ex: 30',
                labelText: 'Idade',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, digite sua idade';
                }
                if (int.tryParse(value) == null || int.parse(value)! <= 0) {
                  return 'Idade deve ser um número positivo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$'))],
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
              decoration: const InputDecoration(
                hintText: 'Ex: 1.75 (em metros)',
                labelText: 'Altura (m)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, digite sua altura';
                }
                if (double.tryParse(value) == null || double.parse(value)! <= 0) {
                  return 'Altura deve ser um número positivo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$'))],
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
              decoration: const InputDecoration(
                hintText: 'Ex: 70.5 (em quilogramas)',
                labelText: 'Peso (kg)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, digite seu peso';
                }
                if (double.tryParse(value) == null || double.parse(value)! <= 0) {
                  return 'Peso deve ser um número positivo';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // O botão "Começar" final é controlado pelo Positioned no build principal
          ],
        ),
      ),
    );
  }
}