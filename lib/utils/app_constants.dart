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

// Chaves para SharedPreferences
class SharedPreferencesKeys {
  static const String isOnboardingCompleted = 'isOnboardingCompleted';
  static const String userName = 'userName';
  static const String userGender = 'userGender';
  static const String userAge = 'userAge';
  static const String userHeight = 'userHeight';
  static const String userWeight = 'userWeight';
  static const String userModality = 'userModality';
  static const String userLevel = 'userLevel';
  static const String userFrequency = 'userFrequency';
  static const String activeWorkoutSheetId = 'activeWorkoutSheetId';
  static const String targetWorkoutsThisWeek = 'targetWorkoutsThisWeek';
  static const String completedWorkoutsThisWeek = 'completedWorkoutsThisWeek';

  // Chaves existentes que foram duplicadas, certifique-se de que estão aqui APENAS UMA VEZ
  static const String activeWorkoutSheetData = 'activeWorkoutSheetData';
  static const String lastWeeklyResetDate = 'lastWeeklyResetDate';
  static const String activityHistory = 'activityHistory';

  // NOVAS CHAVES PARA CONQUISTAS E CONTADORES
  static const String achievementsList = 'achievementsList'; // Chave para a lista completa de conquistas
  static const String totalWorkoutsCompleted = 'totalWorkoutsCompleted'; // Contador de todos os treinos
  static const String weightliftingWorkoutsCompleted = 'weightliftingWorkoutsCompleted'; // Contador de treinos de musculação
  static const String runningWorkoutsCompleted = 'runningWorkoutsCompleted'; // Contador de treinos de corrida
  static const String profileImagePath = 'profileImagePath'; // NOVO: Chave para o caminho da imagem de perfil
}