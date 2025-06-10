// lib/main.dart

import 'package:flutter/material.dart';
import 'package:runfit_app/screens/onboarding_screen.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_text_input_themes.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/services/achievement_service.dart';
import 'package:runfit_app/services/goal_service.dart';

// ADICIONE ESTAS DUAS IMPORTAÇÕES
import 'package:firebase_core/firebase_core.dart'; //
import 'firebase_options.dart'; //

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INICIALIZE O FIREBASE AQUI
  await Firebase.initializeApp( //
    options: DefaultFirebaseOptions.currentPlatform, //
  );

  await AchievementService().initializeAchievements();
  await GoalService().initializeGoals();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunFit App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.primaryColor,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textPrimaryColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppStyles.titleTextStyle.copyWith(fontSize: 22),
        ),
        inputDecorationTheme: AppTextInputThemes.inputDecorationTheme,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryColor,
          onPrimary: AppColors.textPrimaryColor,
          secondary: AppColors.accentColor,
          onSecondary: AppColors.textPrimaryColor,
          background: AppColors.primaryColor,
          onBackground: AppColors.textPrimaryColor,
          surface: AppColors.cardColor,
          onSurface: AppColors.textPrimaryColor,
          error: AppColors.errorColor,
          onError: AppColors.textPrimaryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppStyles.buttonStyle,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentColor,
            textStyle: AppStyles.buttonTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}