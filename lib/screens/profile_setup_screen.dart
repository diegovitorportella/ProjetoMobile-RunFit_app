// lib/screens/profile_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Para os enums
import 'package:runfit_app/screens/main_screen.dart'; // Para navegar após a configuração

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  String? _userGender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String? _userModality;
  String? _userLevel;
  String? _userFrequency;

  late DatabaseReference _userProfileRef;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userProfileRef = FirebaseDatabase.instance.ref('users/${user.uid}/profile');
    } else {
      // Isso não deveria acontecer se o fluxo estiver correto, mas é uma salvaguarda.
      // ignore: avoid_print
      print('ProfileSetupScreen: Usuário não logado, não é possível configurar o perfil.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()), // Ou LoginScreen
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: Usuário não logado. Não foi possível salvar o perfil.', style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
        return;
      }

      try {
        await _userProfileRef.set({
          'name': _nameController.text.trim(),
          'gender': _userGender,
          'age': int.tryParse(_ageController.text),
          'height': double.tryParse(_heightController.text),
          'weight': double.tryParse(_weightController.text),
          'modality': _userModality,
          'level': _userLevel,
          'frequency': _userFrequency,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Perfil configurado com sucesso!', style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.successColor,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('Erro ao salvar perfil inicial no Firebase: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar perfil: $e', style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurar Perfil', style: AppStyles.titleTextStyle.copyWith(fontSize: 22)),
        automaticallyImplyLeading: false, // Impede o botão de voltar no onboarding
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Bem-vindo! Para começar, preencha seu perfil.',
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
                value: _userGender,
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
                    _userGender = newValue;
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
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _userModality,
                decoration: const InputDecoration(
                  labelText: 'Modalidade de Treino',
                ),
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
                dropdownColor: AppColors.cardColor,
                items: WorkoutModality.values.map((WorkoutModality modality) {
                  String formattedName = modality.name.toCapitalized();
                  return DropdownMenuItem<String>(
                    value: modality.name,
                    child: Text(formattedName, style: AppStyles.bodyStyle),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _userModality = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione uma modalidade';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _userLevel,
                decoration: const InputDecoration(
                  labelText: 'Nível de Experiência',
                ),
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
                dropdownColor: AppColors.cardColor,
                items: WorkoutLevel.values.map((WorkoutLevel level) {
                  String formattedName = level.name.toCapitalized();
                  return DropdownMenuItem<String>(
                    value: level.name,
                    child: Text(formattedName, style: AppStyles.bodyStyle),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _userLevel = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione seu nível';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _userFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequência Semanal de Treino',
                ),
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
                dropdownColor: AppColors.cardColor,
                items: WorkoutFrequency.values.map((WorkoutFrequency value) {
                  String formattedName = '';
                  if (value == WorkoutFrequency.duasVezesPorSemana) formattedName = '2x por semana';
                  if (value == WorkoutFrequency.tresVezesPorSemana) formattedName = '3x por semana';
                  if (value == WorkoutFrequency.cincoVezesPorSemana) formattedName = '5x por semana';

                  return DropdownMenuItem<String>(
                    value: value.name,
                    child: Text(formattedName, style: AppStyles.bodyStyle),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _userFrequency = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione sua frequência';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              Center(
                child: ElevatedButton(
                  onPressed: _saveProfileData,
                  style: AppStyles.buttonStyle,
                  child: Text('Salvar e Continuar', style: AppStyles.buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}