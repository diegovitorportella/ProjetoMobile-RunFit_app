// lib/services/goal_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/data/models/goal.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Para SharedPreferencesKeys, enums e FirebaseConstants
// Importação do Firebase Realtime Database
import 'package:firebase_database/firebase_database.dart'; // <--- ADICIONE ESTA LINHA


class GoalService {
  // Singleton Pattern
  static final GoalService _instance = GoalService._internal();

  factory GoalService() {
    return _instance;
  }

  GoalService._internal();

  // Referência ao banco de dados para as metas do usuário específico
  // A estrutura será: /users/{userId}/goals
  late DatabaseReference _userGoalsRef; // <--- MUDANÇA AQUI: Será inicializada


  List<Goal> _userGoals = [];

  // Método para inicializar e carregar as metas
  Future<void> initializeGoals() async {
    // Inicializa a referência do Firebase com o userId fixo
    _userGoalsRef = FirebaseDatabase.instance.ref('users/${FirebaseConstants.userId}/goals'); // <--- MUDANÇA AQUI
    await _loadGoals();
  }

  // Carrega as metas do Firebase (não mais do SharedPreferences)
  Future<void> _loadGoals() async {
    // final prefs = await SharedPreferences.getInstance(); // Não precisa mais
    // final String? goalsJson = prefs.getString(SharedPreferencesKeys.userGoalsList); // Não precisa mais

    final snapshot = await _userGoalsRef.once(); // <--- MUDANÇA AQUI
    final dynamic goalsData = snapshot.snapshot.value; // <--- MUDANÇA AQUI

    if (goalsData != null && goalsData is Map) {
      // Firebase Realtime Database retorna mapas aninhados como LinkedMap<Object?, Object?>
      // É preciso garantir que eles sejam Map<String, dynamic> para o fromJson.
      List<Goal> loadedGoals = [];
      goalsData.forEach((key, value) {
        loadedGoals.add(Goal.fromJson(Map<String, dynamic>.from(value))); // <--- MUDANÇA AQUI
      });
      _userGoals = loadedGoals;
    } else {
      _userGoals = [];
    }
  }

  // Salva a lista atual de metas no Firebase (não mais no SharedPreferences)
  Future<void> _saveGoals() async {
    // final prefs = await SharedPreferences.getInstance(); // Não precisa mais
    // final String jsonString = jsonEncode(_userGoals.map((goal) => goal.toJson()).toList()); // Não precisa mais
    // await prefs.setString(SharedPreferencesKeys.userGoalsList, jsonString); // Não precisa mais

    // Converte a lista de metas para um mapa onde a chave é o ID da meta
    Map<String, dynamic> goalsMap = {};
    for (var goal in _userGoals) {
      goalsMap[goal.id] = goal.toJson();
    }
    await _userGoalsRef.set(goalsMap); // <--- MUDANÇA AQUI
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

  // Método principal para atualizar o progresso das metas
  Future<List<Goal>> updateGoalsProgress({
    required String modality,
    double? durationMinutes,
    double? distanceKm,
    String? completedWorkoutSheetId,
  }) async {
    List<Goal> newlyCompletedGoals = [];

    // Recarrega as metas para garantir que estão atualizadas
    await _loadGoals();

    for (int i = 0; i < _userGoals.length; i++) {
      Goal goal = _userGoals[i];

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
          updatedGoal = goal.copyWith(currentValue: goal.currentValue + 1);
          break;
        case GoalType.weight:
        // Lógica de atualização de peso (manter como está ou implementar se dados de peso forem registrados)
          break;
        case GoalType.workoutSheetCompletion:
          if (completedWorkoutSheetId != null && goal.relatedItemId == completedWorkoutSheetId) {
            updatedGoal = goal.copyWith(currentValue: 1.0);
          }
          break;
      }

      if (!updatedGoal.isCompleted && updatedGoal.currentValue >= updatedGoal.targetValue) {
        updatedGoal = updatedGoal.copyWith(isCompleted: true, completedAt: DateTime.now());
        newlyCompletedGoals.add(updatedGoal);
      }

      _userGoals[i] = updatedGoal;
    }

    await _saveGoals(); // Salva as metas atualizadas no Firebase
    return newlyCompletedGoals;
  }

  // Helpers de conversão de unidades (mantidos iguais)
  double _convertDistanceToGoalUnit(double value, GoalUnit fromUnit, GoalUnit toUnit) {
    if (fromUnit == toUnit) return value;
    if (fromUnit == GoalUnit.km && toUnit == GoalUnit.meters) return value * 1000;
    if (fromUnit == GoalUnit.meters && toUnit == GoalUnit.km) return value / 1000;
    return value;
  }

  double _convertDurationToGoalUnit(double value, GoalUnit fromUnit, GoalUnit toUnit) {
    if (fromUnit == toUnit) return value;
    if (fromUnit == GoalUnit.minutes && toUnit == GoalUnit.hours) return value / 60;
    if (fromUnit == GoalUnit.hours && toUnit == GoalUnit.minutes) return value * 60;
    return value;
  }
}