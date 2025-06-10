// lib/screens/activity_log_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart';
import 'package:runfit_app/data/models/activity_history_entry.dart';
import 'package:runfit_app/services/achievement_service.dart';
import 'package:runfit_app/data/models/achievement.dart'; // Importar modelo de Conquista
import 'package:runfit_app/services/goal_service.dart'; // NOVO: Importar GoalService
import 'package:runfit_app/data/models/goal.dart'; // NOVO: Importar modelo Goal

class ActivityLogScreen extends StatefulWidget {
  final String? selectedModality;

  const ActivityLogScreen({
    super.key,
    this.selectedModality,
  });

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _currentModality;
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<LoggedExercise> _loggedExercises = [];

  final Uuid _uuid = const Uuid();
  final AchievementService _achievementService = AchievementService();
  final GoalService _goalService = GoalService(); // NOVO: Instanciar GoalService

  @override
  void initState() {
    super.initState();
    _currentModality = widget.selectedModality ?? WorkoutModality.musculacao.name;
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addLoggedExercise() {
    setState(() {
      _loggedExercises.add(LoggedExercise(name: '', sets: '', reps: ''));
    });
  }

  void _removeLoggedExercise(int index) {
    setState(() {
      _loggedExercises.removeAt(index);
    });
  }

  Future<void> _showExerciseFormModal({LoggedExercise? exercise, int? index}) async {
    final TextEditingController nameController = TextEditingController(text: exercise?.name);
    final TextEditingController setsController = TextEditingController(text: exercise?.sets);
    final TextEditingController repsController = TextEditingController(text: exercise?.reps);
    final TextEditingController loadController = TextEditingController(text: exercise?.load);
    final TextEditingController notesController = TextEditingController(text: exercise?.notes);

    final _exerciseFormKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondaryColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _exerciseFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              exercise == null ? 'Registrar Exercício' : 'Editar Exercício',
                              style: AppStyles.headingStyle,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: nameController,
                              style: AppStyles.bodyStyle,
                              decoration: AppStyles.inputDecoration.copyWith(labelText: 'Nome do Exercício'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite o nome do exercício.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: setsController,
                                    style: AppStyles.bodyStyle,
                                    keyboardType: TextInputType.number,
                                    decoration: AppStyles.inputDecoration.copyWith(labelText: 'Séries'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Séries?';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: repsController,
                                    style: AppStyles.bodyStyle,
                                    keyboardType: TextInputType.text,
                                    decoration: AppStyles.inputDecoration.copyWith(labelText: 'Repetições'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Reps?';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: loadController,
                              style: AppStyles.bodyStyle,
                              decoration: AppStyles.inputDecoration.copyWith(
                                labelText: 'Carga (opcional)',
                                hintText: 'Ex: 20kg, Peso Corporal',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: notesController,
                              style: AppStyles.bodyStyle,
                              decoration: AppStyles.inputDecoration.copyWith(labelText: 'Notas (opcional)'),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Cancelar', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.textSecondaryColor)),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_exerciseFormKey.currentState!.validate()) {
                                      final newLoggedExercise = LoggedExercise(
                                        name: nameController.text.trim(),
                                        sets: setsController.text.trim(),
                                        reps: repsController.text.trim(),
                                        load: loadController.text.trim().isEmpty ? null : loadController.text.trim(),
                                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                      );
                                      Navigator.of(context).pop(newLoggedExercise);
                                    }
                                  },
                                  style: AppStyles.buttonStyle,
                                  child: Text(exercise == null ? 'Adicionar' : 'Salvar', style: AppStyles.buttonTextStyle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is LoggedExercise) {
        setState(() {
          if (index != null) {
            _loggedExercises[index] = result;
          } else {
            _loggedExercises.add(result);
          }
        });
      }
    });
  }

  Future<void> _saveActivity() async {
    if (_formKey.currentState!.validate()) {
      if (_currentModality == WorkoutModality.musculacao.name && _loggedExercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, adicione pelo menos um exercício de musculação.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      List<String> historyJsonList = prefs.getStringList(SharedPreferencesKeys.activityHistory) ?? [];

      final newEntry = ActivityHistoryEntry(
        id: _uuid.v4(),
        date: DateTime.now(),
        modality: _currentModality,
        activityType: 'Avulsa',
        durationMinutes: double.tryParse(_durationController.text),
        distanceKm: null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        latitude: null,
        longitude: null,
        pathCoordinates: null,
        averagePace: null,
        loggedExercises: _currentModality == WorkoutModality.musculacao.name ? _loggedExercises : null,
      );

      historyJsonList.add(json.encode(newEntry.toJson()));
      await prefs.setStringList(SharedPreferencesKeys.activityHistory, historyJsonList);

      final currentCompleted = prefs.getInt(SharedPreferencesKeys.completedWorkoutsThisWeek) ?? 0;
      await prefs.setInt(SharedPreferencesKeys.completedWorkoutsThisWeek, currentCompleted + 1);

      final unlockedAch = await _achievementService.notifyWorkoutCompleted(_currentModality);
      if (unlockedAch != null && mounted) {
        _showAchievementUnlockedDialog(unlockedAch);
      }

      // NOVO: Atualizar metas ao registrar uma atividade avulsa
      final newlyCompletedGoals = await _goalService.updateGoalsProgress(
        modality: _currentModality,
        durationMinutes: double.tryParse(_durationController.text),
        // Se for musculação, você pode adicionar a lógica para passar a carga total aqui
        // Por enquanto, não estamos somando cargas individuais de exercícios na meta service
      );
      if (mounted) {
        for (var goal in newlyCompletedGoals) {
          _showGoalCompletedDialog(goal);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Atividade de ${_currentModality.toCapitalized()} registrada!', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor.withAlpha((255 * 0.7).round()),
          ),
        );
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    }
  }

  void _showAchievementUnlockedDialog(Achievement achievement) {
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

  // NOVO MÉTODO: Exibe um diálogo de meta concluída
  void _showGoalCompletedDialog(Goal goal) {
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

  @override
  Widget build(BuildContext context) {
    // ... (restante do método build, não precisa ser alterado aqui)
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registrar ${_currentModality.toCapitalized()}',
          style: AppStyles.titleTextStyle.copyWith(fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalhes da Atividade',
                style: AppStyles.headingStyle,
              ),
              const SizedBox(height: 24),
              Text('Modalidade: ${_currentModality.toCapitalized()}', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              if (_currentModality == WorkoutModality.musculacao.name) ...[
                Text(
                  'Exercícios Realizados:',
                  style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _loggedExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _loggedExercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.cardColor.withOpacity(0.7),
                      child: ListTile(
                        title: Text(exercise.name.isEmpty ? 'Exercício sem nome' : exercise.name, style: AppStyles.bodyStyle),
                        subtitle: Text(
                          'Séries: ${exercise.sets}, Repetições: ${exercise.reps} ${exercise.load != null && exercise.load!.isNotEmpty ? '(Carga: ${exercise.load})' : ''}',
                          style: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.textPrimaryColor),
                              onPressed: () => _showExerciseFormModal(exercise: exercise, index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.errorColor),
                              onPressed: () => _removeLoggedExercise(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _addLoggedExercise,
                    icon: const Icon(Icons.add, color: AppColors.primaryColor),
                    label: Text('Adicionar Exercício', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.primaryColor)),
                    style: AppStyles.buttonStyle.copyWith(
                      backgroundColor: MaterialStateProperty.all(AppColors.successColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'Duração total (minutos)',
                  hintText: 'Ex: 60',
                ),
                style: AppStyles.bodyStyle,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite a duração.';
                  }
                  if (double.tryParse(value) == null || double.parse(value)! <= 0) {
                    return 'Duração inválida.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'Notas gerais (opcional)',
                  hintText: 'Adicione observações sobre o treino completo',
                ),
                style: AppStyles.bodyStyle,
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveActivity,
                  style: AppStyles.buttonStyle,
                  child: Text('Registrar Atividade', style: AppStyles.buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}