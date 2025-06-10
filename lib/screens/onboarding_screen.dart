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
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      // Salvar todas as preferências do usuário, incluindo o nome
      await prefs.setBool(SharedPreferencesKeys.isOnboardingCompleted, true);
      await prefs.setString(SharedPreferencesKeys.userName, _nameController.text); // Salva o nome
      await prefs.setString(SharedPreferencesKeys.userGender, _selectedGender!);
      await prefs.setInt(SharedPreferencesKeys.userAge, int.parse(_ageController.text));
      await prefs.setDouble(SharedPreferencesKeys.userHeight, double.parse(_heightController.text));
      await prefs.setDouble(SharedPreferencesKeys.userWeight, double.parse(_weightController.text));

      // As preferências de Modalidade, Nível e Frequência não são mais definidas aqui,
      // mas podem ser salvas com valores padrão se necessário, ou gerenciadas na ProfileScreen.

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo ao RunFit!'),
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Nos conte um pouco sobre você para começarmos!',
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo de Nome
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

              // Campo de Gênero
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

              // Campo de Idade
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

              // Campo de Altura
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$'))], // Permite decimais
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

              // Campo de Peso
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$'))], // Permite decimais
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

              Center(
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  style: AppStyles.buttonStyle,
                  child: Text('Começar', style: AppStyles.buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}