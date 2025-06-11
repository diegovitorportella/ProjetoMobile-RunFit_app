// lib/utils/app_constants.dart

// Extensão para formatar strings de enum para exibição
extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}

// Enums para as opções de configuração do usuário (mantidos para categorizar WorkoutSheets)
enum WorkoutFrequency {
  duasVezesPorSemana,
  tresVezesPorSemana,
  cincoVezesPorSemana,
  // Podemos adicionar mais opções de frequência se necessário
}

enum WorkoutModality {
  corrida,
  musculacao,
  ambos,
}

enum WorkoutLevel {
  iniciante,
  intermediario,
  avancado,
}

enum UserGender {
  masculino,
  feminino,
  naoInformar,
}


// Chaves para SharedPreferences (Mantenha todas estas chaves ativas por enquanto)
class SharedPreferencesKeys {
  static const String isOnboardingCompleted = 'isOnboardingCompleted';
  static const String userName = 'userName'; // <--- RESTAURADO
  static const String userGender = 'userGender'; // <--- RESTAURADO
  static const String userAge = 'userAge'; // <--- RESTAURADO
  static const String userHeight = 'userHeight'; // <--- RESTAURADO
  static const String userWeight = 'userWeight'; // <--- RESTAURADO
  static const String userModality = 'userModality'; // <--- RESTAURADO
  static const String userLevel = 'userLevel'; // <--- RESTAURADO
  static const String userFrequency = 'userFrequency'; // <--- RESTAURADO
  static const String activeWorkoutSheetId = 'activeWorkoutSheetId';
  static const String targetWorkoutsThisWeek = 'targetWorkoutsThisWeek';
  static const String completedWorkoutsThisWeek = 'completedWorkoutsThisWeek';

  // Chaves existentes que foram duplicadas, certifique-se de que estão aqui APENAS UMA VEZ
  static const String activeWorkoutSheetData = 'activeWorkoutSheetData';
  static const String lastWeeklyResetDate = 'lastWeeklyResetDate';
  static const String activityHistory = 'activityHistory';

  // NOVAS CHAVES PARA CONQUISTAS E CONTADORES (Mantenha ativas por enquanto)
  static const String achievementsList = 'achievementsList'; // <--- RESTAURADO
  static const String totalWorkoutsCompleted = 'totalWorkoutsCompleted'; // <--- RESTAURADO
  static const String weightliftingWorkoutsCompleted = 'weightliftingWorkoutsCompleted'; // <--- RESTAURADO
  static const String runningWorkoutsCompleted = 'runningWorkoutsCompleted'; // <--- RESTAURADO
  static const String profileImagePath = 'profileImagePath'; // <--- RESTAURADO
  static const String userGoalsList = 'userGoalsList'; // <--- RESTAURADO
}