// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Para FirebaseConstants, SharedPreferencesKeys e enums
import 'package:runfit_app/screens/main_screen.dart';
// Importação do Firebase Realtime Database
import 'package:firebase_database/firebase_database.dart'; // <--- ADICIONE ESTA LINHA

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Referência ao banco de dados para o perfil do usuário
  late DatabaseReference _userProfileRef; // <--- ADICIONE ESTA LINHA

  @override
  void initState() {
    super.initState();
    // Inicializa a referência do Firebase com o userId fixo
    _userProfileRef = FirebaseDatabase.instance.ref('users/${FirebaseConstants.userId}/profile'); // <--- ADICIONE ESTA LINHA
  }

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

      // Marca o onboarding como concluído no SharedPreferences (ainda é útil aqui)
      await prefs.setBool(SharedPreferencesKeys.isOnboardingCompleted, true);

      // Salva os dados do perfil no Firebase Realtime Database
      try {
        await _userProfileRef.set({ // <--- MUDANÇA PRINCIPAL AQUI
          'name': _nameController.text,
          'gender': _selectedGender!,
          'age': int.parse(_ageController.text),
          'height': double.parse(_heightController.text),
          'weight': double.parse(_weightController.text),
          // Adicione aqui outros campos de perfil que possam ser configurados inicialmente
          // Como modalidade, nível, frequência, se você quiser que o onboarding cubra isso.
          // Por enquanto, apenas os campos básicos de perfil.
        });
        // print('Dados do perfil salvos no Firebase!'); // Opcional para depuração
      } catch (e) {
        // ignore: avoid_print
        print('Erro ao salvar dados do perfil no Firebase: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar( // Feedback de erro
            SnackBar(
              content: Text('Erro ao salvar seu perfil. Tente novamente.', style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
        return; // Não avança se houver erro ao salvar
      }


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
      // ... (suas páginas de onboarding existentes)
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

  // A página do formulário de perfil
  Widget _buildProfileFormPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 100.0),
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
          ],
        ),
      ),
    );
  }
}