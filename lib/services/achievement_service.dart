// lib/services/achievement_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/data/models/achievement.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Para SharedPreferencesKeys e enums

class AchievementService {
  // Singleton Pattern
  static final AchievementService _instance = AchievementService._internal();

  factory AchievementService() {
    return _instance;
  }

  AchievementService._internal();

  // Lista interna de todas as conquistas possíveis (base de dados de conquistas)
  List<Achievement> _allAchievements = [];

  // Método para inicializar e carregar as conquistas
  Future<void> initializeAchievements() async {
    final prefs = await SharedPreferences.getInstance();

    // Defina todas as suas conquistas fixas aqui com IDs únicos
    List<Achievement> defaultAchievements = [
      Achievement(
        id: 'first_workout_completed',
        title: 'Primeiro Treino Concluído!',
        description: 'Parabéns por completar seu primeiro treino!',
        icon: Icons.emoji_events,
      ),
      Achievement(
        id: 'master_weightlifting',
        title: 'Mestre da Musculação!',
        description: 'Complete 5 treinos de musculação para se tornar um mestre.',
        icon: Icons.fitness_center,
      ),
      Achievement(
        id: 'champion_running',
        title: 'Campeão da Corrida!',
        description: 'Complete 5 treinos de corrida para se tornar um campeão.',
        icon: Icons.run_circle,
      ),
      Achievement(
        id: 'consistent_week',
        title: 'Semana Consistente!',
        description: 'Conclua todos os treinos da sua meta semanal.',
        icon: Icons.calendar_today,
      ),
      // NOVO: Exemplo de conquista mais "dinâmica" com base em contadores (total de treinos)
      Achievement(
        id: 'ten_workouts_done',
        title: 'Veterano do Treino!',
        description: 'Complete 10 treinos no total.',
        icon: Icons.star,
      ),
      Achievement(
        id: 'twenty_workouts_done',
        title: 'Super Atleta!',
        description: 'Complete 20 treinos no total.',
        icon: Icons.local_fire_department,
      ),
      // Adicione mais conquistas aqui conforme necessário
    ];

    final String? storedAchievementsJson = prefs.getString(SharedPreferencesKeys.achievementsList);

    if (storedAchievementsJson != null) {
      // Se houver conquistas salvas, carregue-as
      final List<dynamic> jsonList = jsonDecode(storedAchievementsJson);
      _allAchievements = jsonList.map((json) => Achievement.fromJson(json)).toList();

      // Mesclar com as conquistas padrão para adicionar novas ou atualizar existentes
      // Isso é importante para garantir que novas conquistas adicionadas ao 'defaultAchievements'
      // sejam incluídas para usuários existentes.
      for (var defaultAch in defaultAchievements) {
        if (!_allAchievements.any((ach) => ach.id == defaultAch.id)) {
          _allAchievements.add(defaultAch);
        } else {
          // Opcional: Atualizar descrição ou ícone de conquistas existentes se eles mudarem
          final existingAchIndex = _allAchievements.indexWhere((ach) => ach.id == defaultAch.id);
          if (existingAchIndex != -1) {
            final existingAch = _allAchievements[existingAchIndex];
            _allAchievements[existingAchIndex] = Achievement(
              id: defaultAch.id,
              title: defaultAch.title,
              description: defaultAch.description,
              icon: defaultAch.icon,
              isUnlocked: existingAch.isUnlocked, // Mantém o status de desbloqueio
              unlockedDate: existingAch.unlockedDate, // Mantém a data de desbloqueio
            );
          }
        }
      }
    } else {
      // Se não houver conquistas salvas, use as conquistas padrão
      _allAchievements = defaultAchievements;
      await _saveAchievements(); // Salva as conquistas padrão para a primeira vez
    }
  }

  // Retorna a lista de conquistas
  List<Achievement> getAchievements() {
    return List.from(_allAchievements); // Retorna uma cópia para evitar modificações externas
  }

  // Salva a lista atual de conquistas no SharedPreferences
  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_allAchievements.map((ach) => ach.toJson()).toList());
    await prefs.setString(SharedPreferencesKeys.achievementsList, jsonString);
  }

  // Desbloqueia uma conquista específica e a salva
  // Retorna a conquista desbloqueada se foi um novo desbloqueio, ou null.
  Future<Achievement?> unlockAchievement(String achievementId) async {
    final achievementIndex = _allAchievements.indexWhere((ach) => ach.id == achievementId);
    if (achievementIndex != -1 && !_allAchievements[achievementIndex].isUnlocked) {
      final unlockedAchievement = _allAchievements[achievementIndex].copyWith(
        isUnlocked: true,
        unlockedDate: DateTime.now(),
      );
      _allAchievements[achievementIndex] = unlockedAchievement;
      await _saveAchievements();
      return unlockedAchievement; // Retorna a conquista que acabou de ser desbloqueada
    }
    return null; // Nenhuma nova conquista desbloqueada
  }

  // Métodos para incrementar contadores (chamados da HomeScreen ou ActivityLogScreen)
  Future<void> incrementTotalWorkoutsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(SharedPreferencesKeys.totalWorkoutsCompleted) ?? 0;
    await prefs.setInt(SharedPreferencesKeys.totalWorkoutsCompleted, count + 1);
  }

  Future<void> incrementWeightliftingWorkoutsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(SharedPreferencesKeys.weightliftingWorkoutsCompleted) ?? 0;
    await prefs.setInt(SharedPreferencesKeys.weightliftingWorkoutsCompleted, count + 1);
  }

  Future<void> incrementRunningWorkoutsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(SharedPreferencesKeys.runningWorkoutsCompleted) ?? 0;
    await prefs.setInt(SharedPreferencesKeys.runningWorkoutsCompleted, count + 1);
  }

  /// NOVO MÉTODO: Centraliza a notificação de treino concluído e retorna a conquista desbloqueada (se houver)
  Future<Achievement?> notifyWorkoutCompleted(String modality) async {
    await incrementTotalWorkoutsCompleted();

    if (modality.toLowerCase() == WorkoutModality.musculacao.name.toLowerCase()) {
      await incrementWeightliftingWorkoutsCompleted();
    } else if (modality.toLowerCase() == WorkoutModality.corrida.name.toLowerCase()) {
      await incrementRunningWorkoutsCompleted();
    }
    // Chame a verificação de conquistas após atualizar os contadores
    return await checkAndUnlockAchievements(modality); // Retorna a conquista desbloqueada
  }


  // Método para verificar e desbloquear conquistas com base nos contadores
  Future<Achievement?> checkAndUnlockAchievements(String? modality) async {
    final prefs = await SharedPreferences.getInstance();
    Achievement? unlockedAchievement; // Para armazenar a primeira conquista desbloqueada

    // 1. Conquista de Primeiro Treino Concluído
    final totalWorkouts = (prefs.getInt(SharedPreferencesKeys.totalWorkoutsCompleted) ?? 0);
    if (totalWorkouts >= 1) {
      final result = await unlockAchievement('first_workout_completed');
      if (result != null) unlockedAchievement = result;
    }

    // 2. Conquistas de Modalidade (Mestre da Musculação / Campeão da Corrida)
    if (modality != null) {
      if (modality.toLowerCase() == WorkoutModality.musculacao.name.toLowerCase()) {
        final weightliftingWorkouts = (prefs.getInt(SharedPreferencesKeys.weightliftingWorkoutsCompleted) ?? 0);
        if (weightliftingWorkouts >= 5) { // Altere o número conforme a regra da sua conquista
          final result = await unlockAchievement('master_weightlifting');
          if (result != null && unlockedAchievement == null) unlockedAchievement = result;
        }
      } else if (modality.toLowerCase() == WorkoutModality.corrida.name.toLowerCase()) {
        final runningWorkouts = (prefs.getInt(SharedPreferencesKeys.runningWorkoutsCompleted) ?? 0);
        if (runningWorkouts >= 5) { // Altere o número conforme a regra da sua conquista
          final result = await unlockAchievement('champion_running');
          if (result != null && unlockedAchievement == null) unlockedAchievement = result;
        }
      }
    }

    // 3. Conquistas de Total de Treinos
    if (totalWorkouts >= 10) {
      final result = await unlockAchievement('ten_workouts_done');
      if (result != null && unlockedAchievement == null) unlockedAchievement = result;
    }
    if (totalWorkouts >= 20) {
      final result = await unlockAchievement('twenty_workouts_done');
      if (result != null && unlockedAchievement == null) unlockedAchievement = result;
    }

    // A conquista 'Primeira Semana Consistente' será checada no reset semanal na HomeScreen
    return unlockedAchievement; // Retorna a primeira conquista desbloqueada nesta checagem
  }

  // Chamado durante o reset semanal na HomeScreen
  Future<Achievement?> checkConsistentWeekAchievement() async {
    final prefs = await SharedPreferences.getInstance();
    final targetWorkouts = prefs.getInt(SharedPreferencesKeys.targetWorkoutsThisWeek) ?? 0;
    final completedWorkouts = prefs.getInt(SharedPreferencesKeys.completedWorkoutsThisWeek) ?? 0;

    // Só desbloqueia se a meta for maior que 0 e se os treinos concluídos atingirem a meta
    if (targetWorkouts > 0 && completedWorkouts >= targetWorkouts) {
      return await unlockAchievement('consistent_week');
    }
    return null;
  }

  // Método para resetar todos os dados de conquistas e contadores (útil para testes)
  Future<void> resetAllAchievementData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPreferencesKeys.achievementsList);
    await prefs.remove(SharedPreferencesKeys.totalWorkoutsCompleted);
    await prefs.remove(SharedPreferencesKeys.weightliftingWorkoutsCompleted);
    await prefs.remove(SharedPreferencesKeys.runningWorkoutsCompleted);
    await initializeAchievements(); // Reinicializa com as conquistas padrão
    _allAchievements.clear(); // Limpa a lista em memória
    // ignore: avoid_print
    print('Todos os dados de conquistas e contadores foram resetados.');
  }
}