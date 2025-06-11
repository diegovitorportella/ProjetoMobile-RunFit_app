// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:runfit_app/data/models/workout_sheet.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart';
// REMOVIDO: import 'package:runfit_app/screens/activity_log_screen.dart'; // Não usado diretamente aqui, mas em ActivitySelectionScreen
import 'package:runfit_app/data/models/activity_history_entry.dart';
import 'package:uuid/uuid.dart';
import 'package:runfit_app/screens/activity_history_screen.dart';
import 'package:runfit_app/services/achievement_service.dart';
import 'package:runfit_app/data/models/achievement.dart'; // <--- ADICIONE ESTA LINHA
import 'package:runfit_app/screens/profile_screen.dart'; // <--- ADICIONE ESTA LINHA
import 'package:runfit_app/screens/achievements_screen.dart'; // <--- ADICIONE ESTA LINHA
import 'package:runfit_app/screens/activity_selection_screen.dart'; // <--- ADICIONE ESTA LINHA
import 'package:runfit_app/services/goal_service.dart';
import 'package:runfit_app/data/models/goal.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToWorkoutSheets;

  const HomeScreen({super.key, this.onNavigateToWorkoutSheets});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userModality = 'N/A';
  String _userLevel = 'N/A';
  String _userFrequency = 'N/A';
  int _completedWorkoutsThisWeek = 0;
  int _targetWorkoutsThisWeek = 0;
  WorkoutSheet? _activeWorkoutSheet;
  final Uuid _uuid = const Uuid();
  final AchievementService _achievementService = AchievementService();
  final GoalService _goalService = GoalService();

  DatabaseReference? _userProfileRef;
  DatabaseReference? _userActivitiesRef;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userProfileRef = FirebaseDatabase.instance.ref('users/${user.uid}/profile');
      _userActivitiesRef = FirebaseDatabase.instance.ref('users/${user.uid}/activities');
      _loadUserSpecificData();
    } else {
      _userName = 'Visitante';
      // ignore: avoid_print
      print('HomeScreen: Usuário não logado. Algumas funcionalidades podem estar limitadas.');
      _loadDefaultWorkoutSheets();
      _resetWeeklyCountersIfNeeded();
    }
  }

  Future<void> _loadUserSpecificData() async {
    await _loadUserPreferences();
    await _loadActiveWorkoutSheet();
    await _resetWeeklyCountersIfNeeded();
  }


  Future<void> _loadUserPreferences() async {
    if (_userProfileRef == null) {
      // ignore: avoid_print
      print('HomeScreen: _userProfileRef é null, não carregando preferências do Firebase.');
      if (mounted) {
        setState(() {
          _userName = 'Usuário';
          _userModality = 'N/A';
          _userLevel = 'N/A';
          _userFrequency = 'N/A';
        });
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      // _profileImagePath = prefs.getString(SharedPreferencesKeys.profileImagePath); // Se HomeSreen não exibir profile image
    });

    try {
      final snapshot = await _userProfileRef!.once();

      if (!mounted) return;

      final dynamic userData = snapshot.snapshot.value;

      if (userData != null && userData is Map) {
        final Map<String, dynamic> profileData = Map<String, dynamic>.from(userData);

        setState(() {
          _userName = profileData['name'] ?? 'Usuário';
          // Usar ?? 'N/A' para garantir que não são nulos antes de toCapitalized()
          _userModality = profileData['modality'] ?? 'N/A';
          _userLevel = profileData['level'] ?? 'N/A';
          String? freq = profileData['frequency'];
          if (freq != null) {
            if (freq == WorkoutFrequency.duasVezesPorSemana.name) {
              _userFrequency = '2x por semana';
            } else if (freq == WorkoutFrequency.tresVezesPorSemana.name) {
              _userFrequency = '3x por semana';
            } else if (freq == WorkoutFrequency.cincoVezesPorSemana.name) {
              _userFrequency = '5x por semana';
            } else {
              _userFrequency = 'N/A';
            }
          } else {
            _userFrequency = 'N/A';
          }
        });
      } else {
        setState(() {
          _userName = 'Usuário';
          _userModality = 'N/A';
          _userLevel = 'N/A';
          _userFrequency = 'N/A';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao carregar dados do perfil do Firebase na HomeScreen: $e');
      if (mounted) {
        setState(() {
          _userName = 'Usuário';
          _userModality = 'N/A';
          _userLevel = 'N/A';
          _userFrequency = 'N/A';
        });
      }
    }

    if (mounted) {
      setState(() {
        _completedWorkoutsThisWeek = prefs.getInt(SharedPreferencesKeys.completedWorkoutsThisWeek) ?? 0;
        // Certificar-se que _userFrequency é tratado como String antes de comparação
        if (_userFrequency == '2x por semana') {
          _targetWorkoutsThisWeek = 2;
        } else if (_userFrequency == '3x por semana') {
          _targetWorkoutsThisWeek = 3;
        } else if (_userFrequency == '5x por semana') {
          _targetWorkoutsThisWeek = 5;
        } else {
          _targetWorkoutsThisWeek = 0;
        }
      });
    }
  }

  Future<void> _loadActiveWorkoutSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final activeSheetId = prefs.getString(SharedPreferencesKeys.activeWorkoutSheetId);
    final activeSheetJson = prefs.getString(SharedPreferencesKeys.activeWorkoutSheetData);

    if (activeSheetId != null && activeSheetJson != null) {
      if (mounted) {
        setState(() {
          _activeWorkoutSheet = WorkoutSheet.fromJson(jsonDecode(activeSheetJson));
        });
      }
    } else {
      await _loadDefaultWorkoutSheets();
    }
  }

  Future<void> _loadDefaultWorkoutSheets() async {
    try {
      final String response = await rootBundle.loadString('assets/data/workout_sheets.json');
      final List<dynamic> data = json.decode(response);
      final List<WorkoutSheet> defaultSheets =
      data.map((json) => WorkoutSheet.fromJson(json)).toList();

      if (defaultSheets.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final firstSheet = defaultSheets.first;
        firstSheet.isActive = true;
        await prefs.setString(SharedPreferencesKeys.activeWorkoutSheetId, firstSheet.id);
        await prefs.setString(SharedPreferencesKeys.activeWorkoutSheetData, jsonEncode(firstSheet.toJson()));
        if (mounted) {
          setState(() {
            _activeWorkoutSheet = firstSheet;
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao carregar fichas de treino padrão: $e');
    }
  }

  Future<void> _resetWeeklyCountersIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetString = prefs.getString(SharedPreferencesKeys.lastWeeklyResetDate);
    DateTime? lastResetDate = lastResetString != null ? DateTime.parse(lastResetString) : null;

    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));

    if (lastResetDate == null || lastResetDate.isBefore(currentMonday.add(const Duration(hours: -1)))) {
      final unlockedAch = await _achievementService.checkConsistentWeekAchievement();
      if (unlockedAch != null && mounted) {
        _showAchievementUnlockedDialog(unlockedAch);
      }

      await prefs.setInt(SharedPreferencesKeys.completedWorkoutsThisWeek, 0);
      await prefs.setString(SharedPreferencesKeys.lastWeeklyResetDate, now.toIso8601String());

      if (mounted) {
        setState(() {
          _completedWorkoutsThisWeek = 0;
        });
      }
    }
  }

  Future<void> _markExerciseCompleted(int index) async {
    if (_activeWorkoutSheet != null) {
      if (mounted) {
        setState(() {
          _activeWorkoutSheet!.exercises[index].isCompleted =
          !_activeWorkoutSheet!.exercises[index].isCompleted;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          SharedPreferencesKeys.activeWorkoutSheetData, jsonEncode(_activeWorkoutSheet!.toJson()));
    }
  }

  Future<void> _saveActivityToFirebase(ActivityHistoryEntry newEntry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // ignore: avoid_print
      print('Erro: Usuário não logado ao tentar salvar atividade no Firebase.');
      return;
    }
    if (_userActivitiesRef == null) {
      // ignore: avoid_print
      print('HomeScreen: _userActivitiesRef é null, não salvando atividade no Firebase.');
      return;
    }

    try {
      final newActivityKey = _userActivitiesRef!.push().key;

      if (newActivityKey != null) {
        await _userActivitiesRef!.child(newActivityKey).set(newEntry.toJson());
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao salvar ficha de treino no Firebase: $e');
    }
  }

  Future<void> _completeWorkoutSheet() async {
    if (_activeWorkoutSheet != null) {
      bool allCompleted = _activeWorkoutSheet!.exercises.every((e) => e.isCompleted);

      if (!allCompleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Por favor, complete todos os exercícios antes de finalizar a ficha.',
                  style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.warningColor,
            ),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final historyJsonList = prefs.getStringList(SharedPreferencesKeys.activityHistory) ?? [];

      final newEntry = ActivityHistoryEntry(
        id: _uuid.v4(),
        date: DateTime.now(),
        modality: _activeWorkoutSheet!.modality.name,
        activityType: 'Ficha de Treino',
        workoutSheetName: _activeWorkoutSheet!.name,
        workoutSheetData: jsonEncode(_activeWorkoutSheet!.toJson()),
        durationMinutes: null,
        distanceKm: null,
        notes: 'Ficha de treino concluída: ${_activeWorkoutSheet!.name}',
        pathCoordinates: null,
        averagePace: null,
        loggedExercises: null,
      );

      historyJsonList.add(jsonEncode(newEntry.toJson()));
      await prefs.setStringList(SharedPreferencesKeys.activityHistory, historyJsonList);

      await _saveActivityToFirebase(newEntry);


      final currentCompleted = prefs.getInt(SharedPreferencesKeys.completedWorkoutsThisWeek) ?? 0;
      await prefs.setInt(SharedPreferencesKeys.completedWorkoutsThisWeek, currentCompleted + 1);
      if (mounted) {
        setState(() {
          _completedWorkoutsThisWeek = currentCompleted + 1;
        });
      }

      final unlockedAch = await _achievementService.notifyWorkoutCompleted(_activeWorkoutSheet!.modality.name);
      if (unlockedAch != null && mounted) {
        _showAchievementUnlockedDialog(unlockedAch);
      }

      final newlyCompletedGoals = await _goalService.updateGoalsProgress(
        modality: _activeWorkoutSheet!.modality.name,
        completedWorkoutSheetId: _activeWorkoutSheet!.id,
      );
      if (mounted) {
        for (var goal in newlyCompletedGoals) {
          _showGoalCompletedDialog(goal);
        }
      }

      _activeWorkoutSheet = _activeWorkoutSheet!.copyWith(
        exercises: _activeWorkoutSheet!.exercises.map((e) => e.copyWith(isCompleted: false)).toList(),
      );
      await prefs.setString(
          SharedPreferencesKeys.activeWorkoutSheetData, jsonEncode(_activeWorkoutSheet!.toJson()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ficha de treino "${_activeWorkoutSheet!.name}" concluída e registrada!',
                style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
      _loadUserPreferences();
    }
  }

  void _showAchievementUnlockedDialog(Achievement achievement) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: [
              Icon(achievement.icon, color: AppColors.successColor, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Conquista Desbloqueada!', style: AppStyles.headingStyle.copyWith(color: AppColors.successColor)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(achievement.title, style: AppStyles.titleTextStyle.copyWith(fontSize: 22, color: AppColors.textPrimaryColor)),
              const SizedBox(height: 8),
              Text(achievement.description, style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Entendi', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.accentColor)),
            ),
          ],
        );
      },
    );
  }

  void _showGoalCompletedDialog(Goal goal) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: [
              Icon(Icons.flag_outlined, color: AppColors.successColor, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Meta Concluída!', style: AppStyles.headingStyle.copyWith(color: AppColors.successColor)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: AppStyles.titleTextStyle.copyWith(fontSize: 22, color: AppColors.textPrimaryColor)),
              const SizedBox(height: 8),
              Text('Parabéns! Você alcançou sua meta de ${goal.targetValue.toStringAsFixed(goal.type == GoalType.distance || goal.type == GoalType.weight ? 1 : 0)} ${goal.unit.name.toLowerCase()}.', style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Uhuul!', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.accentColor)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToActivityLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActivitySelectionScreen(),
      ),
    ).then((_) {
      _loadUserSpecificData();
      _goalService.initializeGoals();
      _achievementService.initializeAchievements();
    });
  }

  IconData _getModalityIcon(String? modality) {
    switch (modality?.toLowerCase()) {
      case 'corrida':
        return Icons.directions_run;
      case 'musculacao':
        return Icons.fitness_center;
      case 'ambos':
        return Icons.sports_gymnastics;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getLevelIcon(String? level) {
    switch (level?.toLowerCase()) {
      case 'iniciante':
        return Icons.star_outline;
      case 'intermediario':
        return Icons.star;
      case 'avancado':
        return Icons.star_half;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildPreferenceRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondaryColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppStyles.bodyStyle.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
        ),
        Text(
          value,
          style: AppStyles.bodyStyle.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActivityHistoryScreen()),
              );
            },
            tooltip: 'Histórico de Atividades',
          ),
          IconButton(
            icon: const Icon(Icons.military_tech_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AchievementsScreen()),
              );
            },
            tooltip: 'Conquistas',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) {
                _loadUserSpecificData();
              });
            },
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/tela_corrida.png',
            fit: BoxFit.cover,
            colorBlendMode: BlendMode.darken,
            color: Colors.black.withOpacity(0.5),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Olá, $_userName!', style: AppStyles.titleTextStyle),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(color: AppColors.borderColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suas Preferências:', style: AppStyles.headingStyle),
                      const SizedBox(height: 16),

                      _buildPreferenceRow(
                        icon: _getModalityIcon(_userModality),
                        label: 'Modalidade Preferida:',
                        value: _userModality?.toCapitalized() ?? 'Não definida',
                        color: AppColors.textPrimaryColor,
                      ),
                      const SizedBox(height: 8),

                      _buildPreferenceRow(
                        icon: _getLevelIcon(_userLevel),
                        label: 'Nível:',
                        value: _userLevel?.toCapitalized() ?? 'Não definido',
                        color: AppColors.textPrimaryColor,
                      ),
                      const SizedBox(height: 8),

                      _buildPreferenceRow(
                        icon: Icons.calendar_today,
                        label: 'Frequência Semanal:',
                        value: _userFrequency?.toCapitalized() ?? 'Não definida',
                        color: AppColors.textPrimaryColor,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Treinos Concluídos esta semana:',
                        style: AppStyles.bodyStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _targetWorkoutsThisWeek > 0
                                  ? _completedWorkoutsThisWeek / _targetWorkoutsThisWeek
                                  : 0.0,
                              backgroundColor: AppColors.borderColor,
                              color: _completedWorkoutsThisWeek >= _targetWorkoutsThisWeek && _targetWorkoutsThisWeek > 0
                                  ? AppColors.successColor
                                  : AppColors.accentColor,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$_completedWorkoutsThisWeek / $_targetWorkoutsThisWeek',
                            style: AppStyles.bodyStyle.copyWith(
                              color: _completedWorkoutsThisWeek >= _targetWorkoutsThisWeek && _targetWorkoutsThisWeek > 0
                                  ? AppColors.successColor
                                  : AppColors.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Sua Ficha de Treino Ativa:', style: AppStyles.headingStyle),
                const SizedBox(height: 16),
                _activeWorkoutSheet != null
                    ? Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(color: AppColors.accentColor, width: 2.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _activeWorkoutSheet!.name,
                              style: AppStyles.headingStyle.copyWith(color: AppColors.accentColor),
                            ),
                          ),
                          Icon(
                            IconData(_activeWorkoutSheet!.icon ?? Icons.fitness_center.codePoint,
                                fontFamily: 'MaterialIcons'),
                            color: AppColors.accentColor,
                            size: 30,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activeWorkoutSheet!.description,
                        style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text('Exercícios:', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activeWorkoutSheet!.exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _activeWorkoutSheet!.exercises[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: AppColors.primaryColor.withOpacity(0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: BorderSide(
                                  color: exercise.isCompleted
                                      ? AppColors.successColor
                                      : AppColors.borderColor,
                                  width: 1.0),
                            ),
                            child: ListTile(
                              leading: Icon(
                                exercise.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                color: exercise.isCompleted ? AppColors.successColor : AppColors.textSecondaryColor,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: AppStyles.bodyStyle.copyWith(
                                      color: exercise.isCompleted
                                          ? AppColors.textSecondaryColor
                                          : AppColors.textPrimaryColor,
                                      decoration: exercise.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                    ),
                                  ),
                                  Text(
                                    'Séries/Repetições: ${exercise.setsReps}',
                                    style: AppStyles.smallTextStyle,
                                  ),
                                  if (exercise.load != null && exercise.load!.isNotEmpty)
                                    Text(
                                      'Carga: ${exercise.load}',
                                      style: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
                                    ),
                                  if (exercise.notes != null && exercise.notes!.isNotEmpty)
                                    Text(
                                      'Notas: ${exercise.notes!}',
                                      style: AppStyles.smallTextStyle,
                                    ),
                                  if (exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8.0),
                                        child: Image.asset(
                                          exercise.imageUrl!,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 180,
                                            width: double.infinity,
                                            color: AppColors.borderColor,
                                            child: Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: AppColors.textSecondaryColor,
                                                size: 50,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () => _markExerciseCompleted(index),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: _completeWorkoutSheet,
                          style: AppStyles.buttonStyle,
                          child: Text('Concluir Ficha de Treino', style: AppStyles.buttonTextStyle),
                        ),
                      ),
                    ],
                  ),
                )
                    : Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(color: AppColors.borderColor, width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Nenhuma ficha de treino ativa no momento.',
                        style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          widget.onNavigateToWorkoutSheets?.call();
                        },
                        style: AppStyles.buttonStyle,
                        child: Text('Explorar Fichas de Treino', style: AppStyles.buttonTextStyle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: FloatingActionButton.extended(
                    onPressed: _navigateToActivityLog,
                    label: Text(
                      'Registrar Nova Atividade Avulsa',
                      style: AppStyles.buttonTextStyle.copyWith(
                        fontSize: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.primaryColor,
                    ),
                    backgroundColor: AppColors.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}