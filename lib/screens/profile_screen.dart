// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Para FirebaseConstants e enums
import 'package:runfit_app/screens/achievements_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:runfit_app/screens/about_app_screen.dart';
import 'package:runfit_app/screens/goals_screen.dart';
// Importação do Firebase Realtime Database
import 'package:firebase_database/firebase_database.dart'; // <--- ADICIONE ESTA LINHA


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
  String? _profileImagePath; // Este ainda será salvo no SharedPreferences

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Referência ao banco de dados para o perfil do usuário
  late DatabaseReference _userProfileRef; // <--- ADICIONE ESTA LINHA


  @override
  void initState() {
    super.initState();
    // Inicializa a referência do Firebase com o userId fixo
    _userProfileRef = FirebaseDatabase.instance.ref('users/${FirebaseConstants.userId}/profile'); // <--- ADICIONE ESTA LINHA
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

  // Modificado para carregar preferências do Firebase e SharedPreferences (para imagem)
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Carregar imagem de perfil do SharedPreferences (mantido aqui)
    setState(() {
      _profileImagePath = prefs.getString(SharedPreferencesKeys.profileImagePath);
    });

    // Carregar dados do perfil do Firebase Realtime Database
    try {
      final snapshot = await _userProfileRef.once(); // Obtém os dados uma única vez
      final dynamic userData = snapshot.snapshot.value;

      if (userData != null && userData is Map) {
        // Converte para Map<String, dynamic> para segurança de tipo
        final Map<String, dynamic> profileData = Map<String, dynamic>.from(userData);

        setState(() {
          _nameController.text = profileData['name'] ?? '';
          _userGender = profileData['gender'];
          _ageController.text = (profileData['age'] ?? '').toString();
          _heightController.text = (profileData['height'] ?? '').toString();
          _weightController.text = (profileData['weight'] ?? '').toString();
          _userModality = profileData['modality'];
          _userLevel = profileData['level'];
          _userFrequency = profileData['frequency'];
        });
        // print('Dados do perfil carregados do Firebase!'); // Opcional para depuração
      } else {
        // print('Nenhum dado de perfil encontrado no Firebase.'); // Opcional
        // Se não houver dados no Firebase, tente carregar do SharedPreferences (compatibilidade inicial)
        // Isso é um fallback para migrar usuários antigos ou preencher se o onboarding não salvou tudo
        setState(() {
          _nameController.text = prefs.getString(SharedPreferencesKeys.userName) ?? '';
          _userGender = prefs.getString(SharedPreferencesKeys.userGender);
          _ageController.text = (prefs.getInt(SharedPreferencesKeys.userAge) ?? '').toString();
          _heightController.text = (prefs.getDouble(SharedPreferencesKeys.userHeight) ?? '').toString();
          _weightController.text = (prefs.getDouble(SharedPreferencesKeys.userWeight) ?? '').toString();
          _userModality = prefs.getString(SharedPreferencesKeys.userModality);
          _userLevel = prefs.getString(SharedPreferencesKeys.userLevel);
          _userFrequency = prefs.getString(SharedPreferencesKeys.userFrequency);
        });
        // Após carregar do SharedPreferences (se existirem), salve no Firebase para migrar
        if (_nameController.text.isNotEmpty) {
          await _saveUserPreferencesToFirebase(); // Salva no Firebase para persistência futura
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao carregar dados do perfil do Firebase: $e');
      // Em caso de erro no Firebase, tente carregar do SharedPreferences como fallback
      setState(() {
        _nameController.text = prefs.getString(SharedPreferencesKeys.userName) ?? '';
        _userGender = prefs.getString(SharedPreferencesKeys.userGender);
        _ageController.text = (prefs.getInt(SharedPreferencesKeys.userAge) ?? '').toString();
        _heightController.text = (prefs.getDouble(SharedPreferencesKeys.userHeight) ?? '').toString();
        _weightController.text = (prefs.getDouble(SharedPreferencesKeys.userWeight) ?? '').toString();
        _userModality = prefs.getString(SharedPreferencesKeys.userModality);
        _userLevel = prefs.getString(SharedPreferencesKeys.userLevel);
        _userFrequency = prefs.getString(SharedPreferencesKeys.userFrequency);
      });
    }
  }

  // Nova função para salvar apenas no Firebase
  Future<void> _saveUserPreferencesToFirebase() async {
    try {
      await _userProfileRef.set({
        'name': _nameController.text,
        'gender': _userGender,
        'age': int.tryParse(_ageController.text),
        'height': double.tryParse(_heightController.text),
        'weight': double.tryParse(_weightController.text),
        'modality': _userModality,
        'level': _userLevel,
        'frequency': _userFrequency,
        // profileImagePath não vai aqui, pois ele é local no SharedPreferences
      });
      // print('Dados do perfil salvos no Firebase com sucesso!');
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao salvar dados do perfil no Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar seu perfil no Firebase.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  // Função principal para salvar preferências (agora primariamente no Firebase)
  Future<void> _saveUserPreferences() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      // Salva a imagem de perfil no SharedPreferences (mantido aqui)
      if (_profileImagePath != null) {
        await prefs.setString(SharedPreferencesKeys.profileImagePath, _profileImagePath!);
      }

      // Salva o resto das preferências no Firebase
      await _saveUserPreferencesToFirebase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preferências salvas!', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor,
          ),
        );
        // Não é mais necessário recarregar _loadUserPreferences() aqui, pois o Firebase é a fonte
        // e se for necessário um refresh, o StreamBuilder ou uma abordagem de estado mais sofisticada lidaria.
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

      await prefs.setString(SharedPreferencesKeys.profileImagePath, pathOrUrl!); // Ainda salva no SharedPreferences
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
                  if (int.tryParse(value) == null || int.parse(value)! <= 0) {
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
                  if (double.tryParse(value) == null || double.parse(value)! <= 0) {
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
                  if (double.tryParse(value) == null || double.parse(value)! <= 0) {
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

              ListTile(
                leading: Icon(Icons.track_changes, color: AppColors.textPrimaryColor),
                title: Text('Minhas Metas', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.arrow_forward_ios, color: AppColors.textSecondaryColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalsScreen()),
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