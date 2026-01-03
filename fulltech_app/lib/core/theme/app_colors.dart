import 'package:flutter/material.dart';

/// Corporate palette for FULLTECH.
///
/// NOTE: Do not hardcode random new colors across the app.
/// Centralize here and consume via [AppTheme].
class AppColors {
  AppColors._();

  /// Azul intenso (similar al logo).
  static const Color primaryBlue = Color(0xFF0652DD);

  /// Azul corporativo oscuro (para degradados).
  static const Color corporateBlueDark = Color(0xFF002347);

  /// Azul corporativo brillante (para acentos/hover/activo).
  static const Color corporateBlueBright = Color(0xFF0652DD);

  /// Negro corporativo.
  static const Color secondaryBlack = Color(0xFF111111);

  /// Fondo muy claro (moderno, casi blanco).
  static const Color softBackground = Color(0xFFF7F9FC);
  static const Color softSurface = Colors.white;

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [corporateBlueDark, corporateBlueBright],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [corporateBlueDark, corporateBlueBright],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Color sidebarItemHover = Color(0x1AFFFFFF);
  static const Color sidebarItemActiveBg = Color(0x26FFFFFF);
  static const Color sidebarDivider = Color(0x24FFFFFF);
}
