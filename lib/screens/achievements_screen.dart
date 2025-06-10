// lib/screens/achievements_screen.dart

import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Não precisa mais importar diretamente aqui
import 'package:runfit_app/data/models/achievement.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
// import 'package:runfit_app/utils/app_constants.dart'; // Não precisa mais importar diretamente aqui
import 'package:runfit_app/services/achievement_service.dart'; // NOVO: Importe o serviço

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _achievements = [];
  final AchievementService _achievementService = AchievementService(); // Instancia o serviço

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    await _achievementService.initializeAchievements(); // Garante que as conquistas estão carregadas
    setState(() {
      _achievements = _achievementService.getAchievements(); // Pega a lista atualizada
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Conquistas', style: AppStyles.titleTextStyle.copyWith(fontSize: 22)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: _achievements.isEmpty
          ? Center(
        child: Text(
          'Nenhuma conquista encontrada.',
          style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _achievements.length,
        itemBuilder: (context, index) {
          final achievement = _achievements[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: achievement.isUnlocked ? AppColors.cardColor : AppColors.cardColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: achievement.isUnlocked ? AppColors.accentColor : AppColors.borderColor,
                width: 1.5,
              ),
            ),
            elevation: achievement.isUnlocked ? 4 : 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    achievement.icon,
                    size: 48,
                    color: achievement.isUnlocked ? AppColors.successColor : AppColors.textSecondaryColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: AppStyles.headingStyle.copyWith(
                            fontSize: 18,
                            color: achievement.isUnlocked ? AppColors.textPrimaryColor : AppColors.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement.description,
                          style: AppStyles.bodyStyle.copyWith(
                            fontSize: 14,
                            color: achievement.isUnlocked ? AppColors.textPrimaryColor.withOpacity(0.8) : AppColors.textSecondaryColor.withOpacity(0.6),
                          ),
                        ),
                        if (achievement.isUnlocked && achievement.unlockedDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Desbloqueado em: ${achievement.unlockedDate!.day}/${achievement.unlockedDate!.month}/${achievement.unlockedDate!.year}',
                            style: AppStyles.smallTextStyle.copyWith(color: AppColors.successColor),
                          ),
                        ] else if (!achievement.isUnlocked) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Bloqueado',
                            style: AppStyles.smallTextStyle.copyWith(color: AppColors.errorColor, fontWeight: FontWeight.bold),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}