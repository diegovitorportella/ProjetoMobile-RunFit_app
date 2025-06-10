// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart';
import 'package:runfit_app/screens/achievements_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:runfit_app/screens/about_app_screen.dart';
import 'package:runfit_app/screens/goals_screen.dart'; // NOVO: Importar a GoalsScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Dados do usuário
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _userGender;
  String? _userModality;
  String? _userLevel;
  String? _userFrequency;
  String? _profileImagePath;

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString(SharedPreferencesKeys.userName) ?? '';
      _userGender = prefs.getString(SharedPreferencesKeys.userGender);
      _ageController.text = (prefs.getInt(SharedPreferencesKeys.userAge) ?? '').toString();
      _heightController.text = (prefs.getDouble(SharedPreferencesKeys.userHeight) ?? '').toString();
      _weightController.text = (prefs.getDouble(SharedPreferencesKeys.userWeight) ?? '').toString();
      _userModality = prefs.getString(SharedPreferencesKeys.userModality);
      _userLevel = prefs.getString(SharedPreferencesKeys.userLevel);
      _userFrequency = prefs.getString(SharedPreferencesKeys.userFrequency);
      _profileImagePath = prefs.getString(SharedPreferencesKeys.profileImagePath);
    });
  }

  Future<void> _saveUserPreferences() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(SharedPreferencesKeys.userName, _nameController.text);
      if (_userGender != null) {
        await prefs.setString(SharedPreferencesKeys.userGender, _userGender!);
      }
      if (_ageController.text.isNotEmpty) {
        await prefs.setInt(SharedPreferencesKeys.userAge, int.parse(_ageController.text));
      }
      if (_heightController.text.isNotEmpty) {
        await prefs.setDouble(SharedPreferencesKeys.userHeight, double.parse(_heightController.text));
      }
      if (_weightController.text.isNotEmpty) {
        await prefs.setDouble(SharedPreferencesKeys.userWeight, double.parse(_weightController.text));
      }
      if (_userModality != null) {
        await prefs.setString(SharedPreferencesKeys.userModality, _userModality!);
      }
      if (_userLevel != null) {
        await prefs.setString(SharedPreferencesKeys.userLevel, _userLevel!);
      }
      if (_userFrequency != null) {
        await prefs.setString(SharedPreferencesKeys.userFrequency, _userFrequency!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preferências salvas!', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor,
          ),
        );
        _loadUserPreferences();
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.textPrimaryColor),
                title: Text('Escolher da Galeria', style: AppStyles.bodyStyle),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: AppColors.textPrimaryColor),
                title: Text('Tirar Foto', style: AppStyles.bodyStyle),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      String? pathOrUrl;

      if (kIsWeb) {
        pathOrUrl = pickedFile.path;
      } else {
        pathOrUrl = pickedFile.path;
      }

      await prefs.setString(SharedPreferencesKeys.profileImagePath, pathOrUrl!);
      setState(() {
        _profileImagePath = pathOrUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto de perfil atualizada!', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nenhuma imagem selecionada.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.warningColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImageProvider;
    if (_profileImagePath != null) {
      if (kIsWeb) {
        profileImageProvider = NetworkImage(_profileImagePath!);
      } else {
        profileImageProvider = FileImage(File(_profileImagePath!));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.cardColor,
                        backgroundImage: profileImageProvider,
                        child: profileImageProvider == null
                            ? Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.textSecondaryColor,
                        )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.accentColor,
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
                decoration: const InputDecoration(
                  hintText: 'Seu nome',
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
                    return 'Selecione seu gênero';
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
                  hintText: 'Sua idade',
                  labelText: 'Idade',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite sua idade';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Idade inválida';
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
                  hintText: 'Sua altura em metros (ex: 1.75)',
                  labelText: 'Altura (m)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite sua altura';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Altura inválida';
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
                  hintText: 'Seu peso em kg (ex: 70.5)',
                  labelText: 'Peso (kg)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite seu peso';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Peso inválido';
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

              ListTile(
                leading: Icon(Icons.military_tech_outlined, color: AppColors.textPrimaryColor),
                title: Text('Minhas Conquistas', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.arrow_forward_ios, color: AppColors.textSecondaryColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                  );
                },
              ),
              Divider(color: AppColors.borderColor, height: 1),

              // NOVO: ListTile para Metas
              ListTile(
                leading: Icon(Icons.track_changes, color: AppColors.textPrimaryColor),
                title: Text('Minhas Metas', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.arrow_forward_ios, color: AppColors.textSecondaryColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalsScreen()), // Navega para GoalsScreen
                  );
                },
              ),
              Divider(color: AppColors.borderColor, height: 1),

              ListTile(
                leading: Icon(Icons.info_outline, color: AppColors.textPrimaryColor),
                title: Text('Sobre o Aplicativo', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.arrow_forward_ios, color: AppColors.textSecondaryColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutAppScreen()),
                  );
                },
              ),
              Divider(color: AppColors.borderColor, height: 1),
              const SizedBox(height: 16),


              Center(
                child: ElevatedButton(
                  onPressed: _saveUserPreferences,
                  style: AppStyles.buttonStyle,
                  child: Text('Salvar Preferências', style: AppStyles.buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}