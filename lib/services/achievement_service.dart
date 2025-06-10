// lib/services/achievement_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/data/models/achievement.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Para SharedPreferencesKeys, enums e FirebaseConstants
// Importação do Firebase Realtime Database
import 'package:firebase_database/firebase_database.dart'; // <--- ADICIONE ESTA LINHA


class AchievementService {
  // Singleton Pattern
  static final AchievementService _instance = AchievementService._internal();

  factory AchievementService() {
    return _instance;
  }

  AchievementService._internal();

  // Referência ao banco de dados para as conquistas do usuário específico
  // A estrutura será: /users/{userId}/achievements
  late DatabaseReference _userAchievementsRef; // <--- MUDANÇA AQUI: Será inicializada

  // Referências para os contadores no Firebase
  late DatabaseReference _totalWorkoutsRef; // <--- ADICIONE
  late DatabaseReference _weightliftingWorkoutsRef; // <--- ADICIONE
  late DatabaseReference _runningWorkoutsRef; // <--- ADICIONE


  // Lista interna de todas as conquistas possíveis (base de dados de conquistas)
  List<Achievement> _allAchievements = []; // Agora carregada do Firebase, mas ainda com defaults


  // Método para inicializar e carregar as conquistas
  Future<void> initializeAchievements() async {
    // Inicializa as referências do Firebase com o userId fixo
    _userAchievementsRef = FirebaseDatabase.instance.ref('users/${FirebaseConstants.userId}/achievements'); // <--- MUDANÇA AQUI
    _totalWorkoutsRef = FirebaseDatabase.instance.ref('users/${FirebaseConstants.userId}/counters/totalWorkoutsCompleted'); // <--- ADICIONE
    _weightliftingWorkoutsRef = FirebaseDatabase.instance.ref('users/${FirebaseConstants.userId}/counters/weightliftingWorkoutsCompleted'); // <--- ADICIONE
    _runningWorkoutsRef = FirebaseDatabase.instance.ref('users/${FirebaseConstants.userId}/counters/runningWorkoutsCompleted'); // <--- ADICIONE


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

    // Tenta carregar conquistas do Firebase
    final snapshot = await _userAchievementsRef.once(); // <--- MUDANÇA AQUI
    final dynamic storedAchievementsData = snapshot.snapshot.value; // <--- MUDANÇA AQUI

    if (storedAchievementsData != null && storedAchievementsData is Map) {
      // Se houver conquistas salvas no Firebase, carregue-as
      List<Achievement> loadedAchievements = [];
      // Firebase Realtime Database retorna mapas aninhados como LinkedMap<Object?, Object?>
      // É preciso garantir que eles sejam Map<String, dynamic> para o fromJson.
      storedAchievementsData.forEach((key, value) {
        loadedAchievements.add(Achievement.fromJson(Map<String, dynamic>.from(value))); // <--- MUDANÇA AQUI
      });
      _allAchievements = loadedAchievements;

      // Mesclar com as conquistas padrão para adicionar novas ou atualizar existentes
      for (var defaultAch in defaultAchievements) {
        final existingAchIndex = _allAchievements.indexWhere((ach) => ach.id == defaultAch.id);
        if (existingAchIndex == -1) {
          _allAchievements.add(defaultAch);
        } else {
          // Opcional: Atualizar descrição ou ícone de conquistas existentes se eles mudarem
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
    } else {
      // Se não houver conquistas salvas no Firebase, use as conquistas padrão e salve-as
      _allAchievements = defaultAchievements;
      await _saveAchievements(); // Salva as conquistas padrão no Firebase pela primeira vez // <--- MUDANÇA AQUI
    }
  }

  // Retorna a lista de conquistas
  List<Achievement> getAchievements() {
    return List.from(_allAchievements);
  }

  // Salva a lista atual de conquistas no Firebase
  Future<void> _saveAchievements() async {
    // Converte a lista de conquistas para um mapa onde a chave é o ID da conquista
    Map<String, dynamic> achievementsMap = {};
    for (var ach in _allAchievements) {
      achievementsMap[ach.id] = ach.toJson();
    }
    await _userAchievementsRef.set(achievementsMap); // <--- MUDANÇA AQUI
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
      await _saveAchievements(); // Salva no Firebase // <--- MUDANÇA AQUI
      return unlockedAchievement;
    }
    return null;
  }

  // Métodos para incrementar contadores (agora no Firebase)
  Future<void> incrementTotalWorkoutsCompleted() async {
    final snapshot = await _totalWorkoutsRef.once();
    int count = (snapshot.snapshot.value as int?) ?? 0;
    await _totalWorkoutsRef.set(count + 1); // <--- MUDANÇA AQUI
  }

  Future<void> incrementWeightliftingWorkoutsCompleted() async {
    final snapshot = await _weightliftingWorkoutsRef.once();
    int count = (snapshot.snapshot.value as int?) ?? 0;
    await _weightliftingWorkoutsRef.set(count + 1); // <--- MUDANÇA AQUI
  }

  Future<void> incrementRunningWorkoutsCompleted() async {
    final snapshot = await _runningWorkoutsRef.once();
    int count = (snapshot.snapshot.value as int?) ?? 0;
    await _runningWorkoutsRef.set(count + 1); // <--- MUDANÇA AQUI
  }

  // Métodos para obter os contadores (do Firebase)
  Future<int> getTotalWorkoutsCompleted() async {
    final snapshot = await _totalWorkoutsRef.once();
    return (snapshot.snapshot.value as int?) ?? 0; // <--- OBTÉM DO FIREBASE
  }

  Future<int> getWeightliftingWorkoutsCompleted() async {
    final snapshot = await _weightliftingWorkoutsRef.once();
    return (snapshot.snapshot.value as int?) ?? 0; // <--- OBTÉM DO FIREBASE
  }

  Future<int> getRunningWorkoutsCompleted() async {
    final snapshot = await _runningWorkoutsRef.once();
    return (snapshot.snapshot.value as int?) ?? 0; // <--- OBTÉM DO FIREBASE
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
    return await checkAndUnlockAchievements(modality);
  }


  // Método para verificar e desbloquear conquistas com base nos contadores
  Future<Achievement?> checkAndUnlockAchievements(String? modality) async {
    // Não precisamos mais de SharedPreferences para contadores aqui, pois já estamos obtendo do Firebase
    Achievement? unlockedAchievement;

    // 1. Conquista de Primeiro Treino Concluído
    final totalWorkouts = await getTotalWorkoutsCompleted(); // <--- OBTÉM DO FIREBASE
    if (totalWorkouts >= 1) {
      final result = await unlockAchievement('first_workout_completed');
      if (result != null) unlockedAchievement = result;
    }

    // 2. Conquistas de Modalidade (Mestre da Musculação / Campeão da Corrida)
    if (modality != null) {
      if (modality.toLowerCase() == WorkoutModality.musculacao.name.toLowerCase()) {
        final weightliftingWorkouts = await getWeightliftingWorkoutsCompleted(); // <--- OBTÉM DO FIREBASE
        if (weightliftingWorkouts >= 5) {
          final result = await unlockAchievement('master_weightlifting');
          if (result != null && unlockedAchievement == null) unlockedAchievement = result;
        }
      } else if (modality.toLowerCase() == WorkoutModality.corrida.name.toLowerCase()) {
        final runningWorkouts = await getRunningWorkoutsCompleted(); // <--- OBTÉM DO FIREBASE
        if (runningWorkouts >= 5) {
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
    return unlockedAchievement;
  }

  // Chamado durante o reset semanal na HomeScreen
  Future<Achievement?> checkConsistentWeekAchievement() async {
    final prefs = await SharedPreferences.getInstance(); // Ainda usa SharedPreferences para metas semanais
    final targetWorkouts = prefs.getInt(SharedPreferencesKeys.targetWorkoutsThisWeek) ?? 0;
    final completedWorkouts = prefs.getInt(SharedPreferencesKeys.completedWorkoutsThisWeek) ?? 0;

    if (targetWorkouts > 0 && completedWorkouts >= targetWorkouts) {
      return await unlockAchievement('consistent_week');
    }
    return null;
  }

  // Método para resetar todos os dados de conquistas e contadores (útil para testes)
  Future<void> resetAllAchievementData() async {
    // Remove os dados do SharedPreferences (apenas o que estava lá)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPreferencesKeys.achievementsList); // Não usado mais para conquistas
    await prefs.remove(SharedPreferencesKeys.totalWorkoutsCompleted); // Não usado mais para contadores
    await prefs.remove(SharedPreferencesKeys.weightliftingWorkoutsCompleted);
    await prefs.remove(SharedPreferencesKeys.runningWorkoutsCompleted);

    // Remove os dados do Firebase
    await _userAchievementsRef.remove(); // Remove todas as conquistas do usuário no Firebase
    await _totalWorkoutsRef.remove(); // Remove o contador total
    await _weightliftingWorkoutsRef.remove(); // Remove o contador de musculação
    await _runningWorkoutsRef.remove(); // Remove o contador de corrida

    // Reinicializa as conquistas (irá carregar as padrão e salvá-las no Firebase)
    await initializeAchievements();
    _allAchievements.clear(); // Limpa a lista em memória para garantir
    // ignore: avoid_print
    print('Todos os dados de conquistas e contadores foram resetados (Firebase e SharedPreferences).');
  }
}