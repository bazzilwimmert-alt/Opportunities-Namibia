import 'package:flutter/material.dart';

class BaxColors {
  static const Color bg = Color(0xFF0B0B12);
  static const Color surface = Color(0xFF15151F);
  static const Color card = Color(0xFF1C1C2A);
  static const Color primary = Color(0xFF00E5A0); // Bax green
  static const Color accent = Color(0xFF7C4DFF);
  static const Color text = Color(0xFFF5F5FA);
  static const Color muted = Color(0xFF9A9AB0);
}

ThemeData buildBaxTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: BaxColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: BaxColors.primary,
      secondary: BaxColors.accent,
      surface: BaxColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BaxColors.bg,
      elevation: 0,
      centerTitle: false,
    ),
    cardColor: BaxColors.card,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BaxColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BaxColors.primary,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: BaxColors.text,
      displayColor: BaxColors.text,
    ),
  );
}
