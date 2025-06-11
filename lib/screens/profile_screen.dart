// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Para enums
import 'package:runfit_app/screens/achievements_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:runfit_app/screens/about_app_screen.dart';
import 'package:runfit_app/screens/goals_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runfit_app/screens/login_screen.dart';


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

  late DatabaseReference _userProfileRef;


  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userProfileRef = FirebaseDatabase.instance.ref('users/${user.uid}/profile');
      _loadUserPreferences();
    } else {
      // Se não houver usuário logado aqui, o aplicativo deve estar em um estado inválido
      // considerando o fluxo de autenticação. Redirecionar para login.
      // ignore: avoid_print
      print('ProfileScreen: Usuário não logado. Redirecionando para tela de login.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
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

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    // Apenas carrega o caminho da imagem de perfil do SharedPreferences
    setState(() {
      _profileImagePath = prefs.getString(SharedPreferencesKeys.profileImagePath);
    });

    try {
      final snapshot = await _userProfileRef.once();

      if (!mounted) return;

      final dynamic userData = snapshot.snapshot.value;

      if (userData != null && userData is Map) {
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
      } else {
        // Se não houver dados de perfil no Firebase, significa que o usuário
        // pode ter criado a conta, mas não preencheu o perfil inicial.
        // Neste ponto, ele terá que preencher. Os campos ficarão vazios.
        // Opcional: Você pode considerar redirecionar para ProfileSetupScreen aqui
        // se o perfil estiver vazio, mas isso pode gerar loops se não for bem controlado.
        // Por enquanto, apenas os campos ficarão vazios para ele preencher/salvar.
        setState(() {
          _nameController.text = ''; // Limpar para o usuário preencher
          _userGender = null;
          _ageController.text = '';
          _heightController.text = '';
          _weightController.text = '';
          _userModality = null;
          _userLevel = null;
          _userFrequency = null;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao carregar dados do perfil do Firebase: $e');
      if (mounted) {
        setState(() {
          // Em caso de erro, limpe os campos para que o usuário possa tentar novamente
          _nameController.text = '';
          _userGender = null;
          _ageController.text = '';
          _heightController.text = '';
          _weightController.text = '';
          _userModality = null;
          _userLevel = null;
          _userFrequency = null;
        });
      }
    }
  }

  Future<void> _saveUserPreferencesToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // ignore: avoid_print
      print('Erro: Usuário não logado ao tentar salvar perfil no Firebase.');
      return;
    }
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
      });
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

  Future<void> _saveUserPreferences() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      if (_profileImagePath != null) {
        await prefs.setString(SharedPreferencesKeys.profileImagePath, _profileImagePath!);
      }

      await _saveUserPreferencesToFirebase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preferências salvas!', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor,
          ),
        );
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

    if (!mounted) return;

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você foi desconectado.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao fazer logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desconectar: $e', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.errorColor,
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
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _signOut,
                  style: AppStyles.buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(AppColors.errorColor),
                  ),
                  child: Text('Sair da Conta', style: AppStyles.buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}