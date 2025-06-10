// lib/utils/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Cores Primárias
  static const Color primaryColor = Color(0xFF1A1A1A); // Fundo preto (quase preto)
  static const Color accentColor = Color(0xFFE53935); // Vermelho vibrante (foco principal)
  static const Color secondaryAccentColor = Color(0xFFC62828); // Um tom um pouco mais escuro de vermelho

  // Cores do Texto
  static const Color textPrimaryColor = Color(0xFFFFFFFF); // Texto branco
  static const Color textSecondaryColor = Color(0xFFA0A0A0); // Texto cinza claro para detalhes

  // Cores de Componentes
  static const Color cardColor = Color(0xFF2C2C2C); // Cor de fundo de cards e elementos de destaque
  static const Color borderColor = Color(0xFF4A4A4A); // Cor para bordas sutis

  // Cores de Estado
  static const Color successColor = Color(0xFFFFFFFF); // Branco para sucesso (MANTER BRANCO para sucesso)
  static const Color errorColor = Color(0xFFF44336);   // Vermelho para erro
  static const Color warningColor = Color(0xFFFFC107); // Amarelo para aviso
}