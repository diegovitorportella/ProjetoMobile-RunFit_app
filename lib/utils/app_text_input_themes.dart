// lib/utils/app_text_input_themes.dart

import 'package:flutter/material.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart'; // Para AppStyles.bodyStyle

class AppTextInputThemes {
  static InputDecorationTheme get inputDecorationTheme {
    return InputDecorationTheme(
      // Estilo da borda
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: AppColors.borderColor, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: AppColors.accentColor, width: 2.0), // Borda focada será VERMELHA
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: AppColors.errorColor, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: AppColors.errorColor, width: 2.0),
      ),
      // Cor de preenchimento
      filled: true,
      fillColor: AppColors.cardColor.withOpacity(0.5),

      // Estilo do texto do label
      labelStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor), // Label será CINZA CLARO
      // Estilo do texto de hint
      hintStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor.withOpacity(0.7)), // Hint será CINZA CLARO
      // Estilo do texto de erro
      errorStyle: AppStyles.smallTextStyle.copyWith(color: AppColors.errorColor),
      // Estilo do texto digitado
      counterStyle: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
      helperStyle: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
      prefixStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
      suffixStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
    );
  }
}