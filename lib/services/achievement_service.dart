// lib/services/achievement_service.dart

import 'dart:convert'; // Importar para jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runfit_app/data/models/achievement.dart';
import 'package:runfit_app/utils/app_constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();

  factory AchievementService() {
    return _instance;
  }

  AchievementService._internal();

  // Tornar as referências anuláveis
  DatabaseReference? _userAchievementsRef;
  DatabaseReference? _totalWorkoutsRef;
  DatabaseReference? _weightliftingWorkoutsRef;
  DatabaseReference? _runningWorkoutsRef;

  List<Achievement> _allAchievements = [];

  Future<void> initializeAchievements() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userAchievementsRef = FirebaseDatabase.instance.ref('users/${user.uid}/achievements');
      _totalWorkoutsRef = FirebaseDatabase.instance.ref('users/${user.uid}/counters/totalWorkoutsCompleted');
      _weightliftingWorkoutsRef = FirebaseDatabase.instance.ref('users/${user.uid}/counters/weightliftingWorkoutsCompleted');
      _runningWorkoutsRef = FirebaseDatabase.instance.ref('users/${user.uid}/counters/runningWorkoutsCompleted');

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
      ];

      try {
        final snapshot = await _userAchievementsRef!.once();
        final dynamic storedAchievementsData = snapshot.snapshot.value;

        if (storedAchievementsData != null && storedAchievementsData is Map) {
          List<Achievement> loadedAchievements = [];
          storedAchievementsData.forEach((key, value) {
            try {
              // AQUI ESTÁ A NOVA ABORDAGEM: Serializar e desserializar
              final Map<String, dynamic> typedValue = jsonDecode(jsonEncode(value));
              loadedAchievements.add(Achievement.fromJson(typedValue));
            } catch (e) {
              print('Erro ao processar conquista do Firebase (chave: $key): $e, dado: $value');
            }
          });
          _allAchievements = loadedAchievements;

          for (var defaultAch in defaultAchievements) {
            final existingAchIndex = _allAchievements.indexWhere((ach) => ach.id == defaultAch.id);
            if (existingAchIndex == -1) {
              _allAchievements.add(defaultAch);
            } else {
              final existingAch = _allAchievements[existingAchIndex];
              _allAchievements[existingAchIndex] = Achievement(
                id: defaultAch.id,
                title: defaultAch.title,
                description: defaultAch.description,
                icon: defaultAch.icon,
                isUnlocked: existingAch.isUnlocked,
                unlockedDate: existingAch.unlockedDate,
              );
            }
          }
        } else {
          _allAchievements = defaultAchievements;
          await _saveAchievements();
        }
      } catch (e) {
        print('Erro ao carregar ou salvar conquistas padrão: $e');
        _allAchievements = defaultAchievements; // fallback para defaults se houver erro no Firebase
      }
    } else {
      // Se não houver usuário logado, defina as referências como null
      _userAchievementsRef = null;
      _totalWorkoutsRef = null;
      _weightliftingWorkoutsRef = null;
      _runningWorkoutsRef = null;
      _allAchievements = []; // Limpa conquistas em memória
      print('AchievementService: Usuário não logado. Conquistas não serão carregadas/salvas no Firebase.');
    }
  }

  List<Achievement> getAchievements() {
    return List.from(_allAchievements);
  }

  Future<void> _saveAchievements() async {
    if (_userAchievementsRef == null) {
      print('AchievementService: Não é possível salvar conquistas sem usuário logado.');
      return;
    }
    Map<String, dynamic> achievementsMap = {};
    for (var ach in _allAchievements) {
      achievementsMap[ach.id] = ach.toJson();
    }
    await _userAchievementsRef!.set(achievementsMap);
  }

  Future<Achievement?> unlockAchievement(String achievementId) async {
    if (_userAchievementsRef == null) {
      print('AchievementService: Não é possível desbloquear conquista sem usuário logado.');
      return null;
    }

    final achievementIndex = _allAchievements.indexWhere((ach) => ach.id == achievementId);
    if (achievementIndex != -1 && !_allAchievements[achievementIndex].isUnlocked) {
      final unlockedAchievement = _allAchievements[achievementIndex].copyWith(
        isUnlocked: true,
        unlockedDate: DateTime.now(),
      );
      _allAchievements[achievementIndex] = unlockedAchievement;
      await _saveAchievements();
      return unlockedAchievement;
    }
    return null;
  }

  Future<void> incrementTotalWorkoutsCompleted() async {
    if (_totalWorkoutsRef == null) {
      print('AchievementService: Não é possível incrementar contador sem usuário logado.');
      return;
    }
    final snapshot = await _totalWorkoutsRef!.once();
    int count = (snapshot.snapshot.value as int?) ?? 0;
    await _totalWorkoutsRef!.set(count + 1);
  }

  Future<void> incrementWeightliftingWorkoutsCompleted() async {
    if (_weightliftingWorkoutsRef == null) {
      print('AchievementService: Não é possível incrementar contador sem usuário logado.');
      return;
    }
    final snapshot = await _weightliftingWorkoutsRef!.once();
    int count = (snapshot.snapshot.value as int?) ?? 0;
    await _weightliftingWorkoutsRef!.set(count + 1);
  }

  Future<void> incrementRunningWorkoutsCompleted() async {
    if (_runningWorkoutsRef == null) {
      print('AchievementService: Não é possível incrementar contador sem usuário logado.');
      return;
    }
    final snapshot = await _runningWorkoutsRef!.once();
    int count = (snapshot.snapshot.value as int?) ?? 0;
    await _runningWorkoutsRef!.set(count + 1);
  }

  Future<int> getTotalWorkoutsCompleted() async {
    if (_totalWorkoutsRef == null) {
      print('AchievementService: Não é possível obter contador sem usuário logado.');
      return 0;
    }
    final snapshot = await _totalWorkoutsRef!.once();
    return (snapshot.snapshot.value as int?) ?? 0;
  }

  Future<int> getWeightliftingWorkoutsCompleted() async {
    if (_weightliftingWorkoutsRef == null) {
      print('AchievementService: Não é possível obter contador sem usuário logado.');
      return 0;
    }
    final snapshot = await _weightliftingWorkoutsRef!.once();
    return (snapshot.snapshot.value as int?) ?? 0;
  }

  Future<int> getRunningWorkoutsCompleted() async {
    if (_runningWorkoutsRef == null) {
      print('AchievementService: Não é possível obter contador sem usuário logado.');
      return 0;
    }
    final snapshot = await _runningWorkoutsRef!.once();
    return (snapshot.snapshot.value as int?) ?? 0;
  }

  Future<Achievement?> notifyWorkoutCompleted(String modality) async {
    await incrementTotalWorkoutsCompleted();

    if (modality.toLowerCase() == WorkoutModality.musculacao.name.toLowerCase()) {
      await incrementWeightliftingWorkoutsCompleted();
    } else if (modality.toLowerCase() == WorkoutModality.corrida.name.toLowerCase()) {
      await incrementRunningWorkoutsCompleted();
    }
    return await checkAndUnlockAchievements(modality);
  }

  Future<Achievement?> checkAndUnlockAchievements(String? modality) async {
    Achievement? unlockedAchievement;

    final totalWorkouts = await getTotalWorkoutsCompleted();
    if (totalWorkouts >= 1) {
      final result = await unlockAchievement('first_workout_completed');
      if (result != null) unlockedAchievement = result;
    }

    if (modality != null) {
      if (modality.toLowerCase() == WorkoutModality.musculacao.name.toLowerCase()) {
        final weightliftingWorkouts = await getWeightliftingWorkoutsCompleted();
        if (weightliftingWorkouts >= 5) {
          final result = await unlockAchievement('master_weightlifting');
          if (result != null && unlockedAchievement == null) unlockedAchievement = result;
        }
      } else if (modality.toLowerCase() == WorkoutModality.corrida.name.toLowerCase()) {
        final runningWorkouts = await getRunningWorkoutsCompleted();
        if (runningWorkouts >= 5) {
          final result = await unlockAchievement('champion_running');
          if (result != null && unlockedAchievement == null) unlockedAchievement = result;
        }
      }
    }

    if (totalWorkouts >= 10) {
      final result = await unlockAchievement('ten_workouts_done');
      if (result != null && unlockedAchievement == null) unlockedAchievement = result;
    }
    if (totalWorkouts >= 20) {
      final result = await unlockAchievement('twenty_workouts_done');
      if (result != null && unlockedAchievement == null) unlockedAchievement = result;
    }

    return unlockedAchievement;
  }

  Future<Achievement?> checkConsistentWeekAchievement() async {
    final prefs = await SharedPreferences.getInstance();
    final targetWorkouts = prefs.getInt(SharedPreferencesKeys.targetWorkoutsThisWeek) ?? 0;
    final completedWorkouts = prefs.getInt(SharedPreferencesKeys.completedWorkoutsThisWeek) ?? 0;

    if (targetWorkouts > 0 && completedWorkouts >= targetWorkouts) {
      return await unlockAchievement('consistent_week');
    }
    return null;
  }

  Future<void> resetAllAchievementData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPreferencesKeys.achievementsList);
    await prefs.remove(SharedPreferencesKeys.totalWorkoutsCompleted);
    await prefs.remove(SharedPreferencesKeys.weightliftingWorkoutsCompleted);
    await prefs.remove(SharedPreferencesKeys.runningWorkoutsCompleted);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseDatabase.instance.ref('users/${user.uid}/achievements').remove();
      await FirebaseDatabase.instance.ref('users/${user.uid}/counters/totalWorkoutsCompleted').remove();
      await FirebaseDatabase.instance.ref('users/${user.uid}/counters/weightliftingWorkoutsCompleted').remove();
      await FirebaseDatabase.instance.ref('users/${user.uid}/counters/runningWorkoutsCompleted').remove();
    } else {
      print('Não é possível resetar dados de conquistas no Firebase: Usuário não logado.');
    }

    // Após resetar, re-inicializa as conquistas (irá carregar as padrão e salvá-las no Firebase se houver usuário)
    await initializeAchievements();
    _allAchievements.clear();
    print('Todos os dados de conquistas e contadores foram resetados (Firebase e SharedPreferences).');
  }
}