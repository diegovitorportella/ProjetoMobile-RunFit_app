// lib/main.dart

import 'package:flutter/material.dart';
import 'package:runfit_app/screens/splash_screen.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_text_input_themes.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/services/achievement_service.dart'; // Importe o serviço

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Garante que o Flutter está inicializado
  await AchievementService().initializeAchievements(); // Inicializa o serviço e carrega dados
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
          secondary: AppColors.accentColor, // Cor de destaque principal (agora vermelho)
          onSecondary: AppColors.textPrimaryColor, // Texto/ícone sobre o destaque
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
            foregroundColor: AppColors.accentColor, // MANTENHA VERMELHO se quiser que TextButton seja vermelho
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
      home: const SplashScreen(),
    );
  }
}