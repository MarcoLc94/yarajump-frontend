import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  // TODO: ajustar a los colores de la marca de Yara Jumping
  static const primario = Color(0xFFD6247A); // magenta
  static const secundario = Color(0xFF6A1B9A); // morado
  static const activo = Color(0xFF2E7D32);
  static const porVencer = Color(0xFFEF6C00);
  static const expirado = Color(0xFFC62828);
  static const whatsapp = Color(0xFF25D366);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primario,
          secondary: AppColors.secundario,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
      );
}
