// lib/services/goal_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/data/models/goal.dart'; // Importa o modelo Goal
import 'package:runfit_app/utils/app_constants.dart'; // Para SharedPreferencesKeys e enums

class GoalService {
  // Singleton Pattern
  static final GoalService _instance = GoalService._internal();

  factory GoalService() {
    return _instance;
  }

  GoalService._internal();

  List<Goal> _userGoals = [];

  // Método para inicializar e carregar as metas
  Future<void> initializeGoals() async {
    await _loadGoals();
  }

  // Carrega as metas do SharedPreferences
  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? goalsJson = prefs.getString(SharedPreferencesKeys.userGoalsList);

    if (goalsJson != null) {
      final List<dynamic> jsonList = jsonDecode(goalsJson);
      _userGoals = jsonList.map((json) => Goal.fromJson(json)).toList();
    } else {
      _userGoals = [];
    }
  }

  // Salva a lista atual de metas no SharedPreferences
  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_userGoals.map((goal) => goal.toJson()).toList());
    await prefs.setString(SharedPreferencesKeys.userGoalsList, jsonString);
  }

  // Retorna uma cópia da lista de metas
  List<Goal> getGoals() {
    return List.from(_userGoals);
  }

  // Adiciona ou atualiza uma meta
  Future<void> addOrUpdateGoal(Goal newGoal) async {
    final int index = _userGoals.indexWhere((g) => g.id == newGoal.id);
    if (index != -1) {
      _userGoals[index] = newGoal;
    } else {
      _userGoals.add(newGoal);
    }
    await _saveGoals();
  }

  // Remove uma meta
  Future<void> deleteGoal(String goalId) async {
    _userGoals.removeWhere((g) => g.id == goalId);
    await _saveGoals();
  }

  // NOVO: Método principal para atualizar o progresso das metas
  // Será chamado após a conclusão de qualquer atividade
  Future<List<Goal>> updateGoalsProgress({
    required String modality,
    double? durationMinutes,
    double? distanceKm,
    // Add parameters for weightlifting, if applicable, like total weight lifted for a session
    String? completedWorkoutSheetId, // Para metas de conclusão de ficha específica
  }) async {
    List<Goal> newlyCompletedGoals = [];

    // Recarrega as metas para garantir que estão atualizadas (evita dessincronização)
    await _loadGoals();

    for (int i = 0; i < _userGoals.length; i++) {
      Goal goal = _userGoals[i];

      // Ignora metas já completas
      if (goal.isCompleted) continue;

      Goal updatedGoal = goal;

      switch (goal.type) {
        case GoalType.distance:
          if (distanceKm != null && (modality == WorkoutModality.corrida.name || modality == WorkoutModality.ambos.name)) {
            double convertedDistance = _convertDistanceToGoalUnit(distanceKm, GoalUnit.km, goal.unit);
            updatedGoal = goal.copyWith(currentValue: goal.currentValue + convertedDistance);
          }
          break;
        case GoalType.duration:
          if (durationMinutes != null) {
            double convertedDuration = _convertDurationToGoalUnit(durationMinutes, GoalUnit.minutes, goal.unit);
            updatedGoal = goal.copyWith(currentValue: goal.currentValue + convertedDuration);
          }
          break;
        case GoalType.frequency:
        // A frequência pode ser tratada como 1 treino = 1 incremento para metas de frequência
          updatedGoal = goal.copyWith(currentValue: goal.currentValue + 1);
          break;
        case GoalType.weight:
        // Implementar lógica de atualização de peso aqui no futuro
        // Por exemplo, somar carga total levantada na sessão se houver dados detalhados
        // Para MVP, pode ser um placeholder ou requer entrada manual na meta
          break;
        case GoalType.workoutSheetCompletion:
          if (completedWorkoutSheetId != null && goal.relatedItemId == completedWorkoutSheetId) {
            updatedGoal = goal.copyWith(currentValue: 1.0); // Marca como 100% completo
          }
          break;
      }

      // Verifica se a meta foi concluída
      if (!updatedGoal.isCompleted && updatedGoal.currentValue >= updatedGoal.targetValue) {
        updatedGoal = updatedGoal.copyWith(isCompleted: true, completedAt: DateTime.now());
        newlyCompletedGoals.add(updatedGoal);
      }

      _userGoals[i] = updatedGoal;
    }

    await _saveGoals();
    return newlyCompletedGoals; // Retorna as metas recém-concluídas
  }

  // Helpers de conversão de unidades (simplificados para o MVP)
  double _convertDistanceToGoalUnit(double value, GoalUnit fromUnit, GoalUnit toUnit) {
    if (fromUnit == toUnit) return value;
    // Conversões básicas (pode ser expandido)
    if (fromUnit == GoalUnit.km && toUnit == GoalUnit.meters) return value * 1000;
    if (fromUnit == GoalUnit.meters && toUnit == GoalUnit.km) return value / 1000;
    // Adicionar outras conversões (milhas, etc.)
    return value; // Retorna o valor original se não houver conversão definida
  }

  double _convertDurationToGoalUnit(double value, GoalUnit fromUnit, GoalUnit toUnit) {
    if (fromUnit == toUnit) return value;
    // Conversões básicas
    if (fromUnit == GoalUnit.minutes && toUnit == GoalUnit.hours) return value / 60;
    if (fromUnit == GoalUnit.hours && toUnit == GoalUnit.minutes) return value * 60;
    return value;
  }
}