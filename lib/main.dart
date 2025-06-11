// lib/main.dart

import 'package:flutter/material.dart';
import 'package:runfit_app/screens/onboarding_screen.dart';
import 'package:runfit_app/screens/login_screen.dart'; // Importe a tela de login
import 'package:runfit_app/screens/main_screen.dart'; // Importe a tela principal (sua MainScreen, para o caso de login)
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_text_input_themes.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/services/achievement_service.dart';
import 'package:runfit_app/services/goal_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- ADICIONE ESTA IMPORTAÇÃO
import 'package:shared_preferences/shared_preferences.dart'; // <--- ADICIONE ESTA IMPORTAÇÃO
import 'package:runfit_app/utils/app_constants.dart'; // <--- ADICIONE ESTA IMPORTAÇÃO (para SharedPreferencesKeys)
import 'firebase_options.dart';

// Função de nível superior para verificar o status do onboarding
Future<bool> _checkOnboardingStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(SharedPreferencesKeys.isOnboardingCompleted) ?? false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicialize os serviços após o Firebase estar pronto
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
      home: StreamBuilder<User?>( // <--- Usa StreamBuilder para ouvir o estado de autenticação
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Carregando
          }
          if (snapshot.hasData) {
            // Usuário logado
            return const MainScreen();
          } else {
            // Usuário não logado, verificar onboarding
            return FutureBuilder<bool>(
              future: _checkOnboardingStatus(), // Chama a função de nível superior
              builder: (context, onboardingSnapshot) {
                if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (onboardingSnapshot.data == true) {
                  return const LoginScreen(); // Onboarding concluído, vai para login
                } else {
                  return const OnboardingScreen(); // Onboarding não concluído, vai para onboarding
                }
              },
            );
          }
        },
      ),
    );
  }
}