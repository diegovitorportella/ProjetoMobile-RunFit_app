// lib/services/goal_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/data/models/goal.dart';
import 'package:runfit_app/utils/app_constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';


class GoalService {
  // Singleton Pattern
  static final GoalService _instance = GoalService._internal();

  factory GoalService() {
    return _instance;
  }

  GoalService._internal();

  // Referência ao banco de dados para as metas do usuário específico
  // Tornar a referência anulável
  DatabaseReference? _userGoalsRef;


  List<Goal> _userGoals = [];

  // Método para inicializar e carregar as metas
  Future<void> initializeGoals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userGoalsRef = FirebaseDatabase.instance.ref('users/${user.uid}/goals');
      await _loadGoals();
    } else {
      // Se não houver usuário logado, defina a referência como null
      _userGoalsRef = null;
      _userGoals = []; // Limpa metas em memória
      // ignore: avoid_print
      print('GoalService: Usuário não logado. Metas não serão carregadas/salvas no Firebase.');
    }
  }

  // Carrega as metas do Firebase (não mais do SharedPreferences)
  Future<void> _loadGoals() async {
    // Adicione a verificação de nulidade antes de usar a referência
    if (_userGoalsRef == null) {
      // ignore: avoid_print
      print('GoalService: Não é possível carregar metas sem usuário logado.');
      return;
    }

    final snapshot = await _userGoalsRef!.once(); // Use '!' após verificar null
    final dynamic goalsData = snapshot.snapshot.value;

    if (goalsData != null && goalsData is Map) {
      List<Goal> loadedGoals = [];
      goalsData.forEach((key, value) {
        loadedGoals.add(Goal.fromJson(Map<String, dynamic>.from(value)));
      });
      _userGoals = loadedGoals;
    } else {
      _userGoals = [];
    }
  }

  // Salva a lista atual de metas no Firebase (não mais no SharedPreferences)
  Future<void> _saveGoals() async {
    // Adicione a verificação de nulidade antes de usar a referência
    if (_userGoalsRef == null) {
      // ignore: avoid_print
      print('GoalService: Não é possível salvar metas sem usuário logado.');
      return;
    }

    Map<String, dynamic> goalsMap = {};
    for (var goal in _userGoals) {
      goalsMap[goal.id] = goal.toJson();
    }
    await _userGoalsRef!.set(goalsMap); // Use '!' após verificar null
  }

  // Retorna uma cópia da lista de metas
  List<Goal> getGoals() {
    // Mesmo que a referência seja nula, a lista em memória pode ser retornada (vazia)
    return List.from(_userGoals);
  }

  // Adiciona ou atualiza uma meta
  Future<void> addOrUpdateGoal(Goal newGoal) async {
    // Adicione a verificação de nulidade antes de prosseguir
    if (_userGoalsRef == null) {
      // ignore: avoid_print
      print('GoalService: Não é possível adicionar/atualizar meta sem usuário logado.');
      return;
    }

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
    // Adicione a verificação de nulidade antes de prosseguir
    if (_userGoalsRef == null) {
      // ignore: avoid_print
      print('GoalService: Não é possível deletar meta sem usuário logado.');
      return;
    }

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
    // Adicione a verificação de nulidade antes de prosseguir
    if (_userGoalsRef == null) {
      // ignore: avoid_print
      print('GoalService: Não é possível atualizar progresso de metas sem usuário logado.');
      return [];
    }

    List<Goal> newlyCompletedGoals = [];

    // Recarrega as metas para garantir que estão atualizadas
    await _loadGoals(); // _loadGoals já tem a verificação interna

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

    await _saveGoals(); // _saveGoals já tem a verificação interna
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