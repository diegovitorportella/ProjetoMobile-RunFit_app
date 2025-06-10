// lib/utils/app_styles.dart

import 'package:flutter/material.dart';
import 'package:runfit_app/utils/app_colors.dart';

// REMOVA O SEGUINTE BLOCO SE ESTIVER AQUI:
// extension StringCasingExtension on String {
//   String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
//   String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
// }

class AppStyles {
  // Text Styles
  static const TextStyle titleTextStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor, // Branco
  );

  static const TextStyle headingStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor, // Branco
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    color: AppColors.textPrimaryColor, // Branco
  );

  static const TextStyle smallTextStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    color: AppColors.textSecondaryColor, // Cinza claro para detalhes menores
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor, // Texto dos botões (branco)
  );

  static ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.accentColor, // Cor de fundo do botão (agora vermelho)
    foregroundColor: AppColors.textPrimaryColor, // Cor do texto/ícone do botão (branco)
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
    textStyle: buttonTextStyle, // Usa o TextStyle definido acima
    elevation: 5,
    shadowColor: AppColors.accentColor.withOpacity(0.5), // Sombra do botão (vermelha, com opacidade)
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
  );

  // Estilo padrão para Input Decoration (campos de formulário)
  static InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: AppColors.cardColor, // Fundo do campo de input (cinza escuro)
    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: AppColors.borderColor), // Borda padrão (cinza)
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: AppColors.borderColor, width: 1.0), // Borda quando habilitado (cinza)
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: AppColors.accentColor, width: 2.0), // Borda quando focado (vermelha)
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: AppColors.errorColor, width: 1.0), // Borda de erro (vermelha)
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: AppColors.errorColor, width: 2.0), // Borda de erro focada (vermelha)
    ),
    labelStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor), // Texto do label (cinza claro)
    hintStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor.withOpacity(0.7)), // Texto de hint (cinza claro, mais transparente)
    errorStyle: AppStyles.smallTextStyle.copyWith(color: AppColors.errorColor, fontWeight: FontWeight.bold), // Texto de erro (vermelho, bold)
    counterStyle: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
    helperStyle: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
    prefixStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
    suffixStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
  );
}