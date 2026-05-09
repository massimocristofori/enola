import 'package:flutter/material.dart';

class EnolaTheme {
  EnolaTheme._();

  // ── High-Energy Game Palette ───────────────────────────────────────────
  static const Color background  = Color(0xFFFFFFFF); // Pure White
  static const Color surface     = Color(0xFFF8F7FF); // Very light violet tint
  static const Color surfaceHigh = Color(0xFFF0EEFF); 
  
  static const Color accent      = Color(0xFF39d2c0); // Vivid Violet
  static const Color secondary   = Color(0xFFEC4899); // Electric Pink
  static const Color accentSoft  = Color(0x267C3AED); 
  
  static const Color textPrimary = Color(0xFF1F2937); // Deep Charcoal
  static const Color textSecond  = Color(0xFF6B7280); // Cool Grey
  
  static const Color correct     = Color(0xFF10B981); // Bright Emerald
  static const Color wrong       = Color(0xFFFF4B4B); // Candy Red
  static const Color border      = Color(0xFFE5E7EB);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: accent,
      secondary: secondary,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Serif',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, color: textSecond, height: 1.5),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.8,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: border, width: 1), // ✅ Corrected parameter name
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: accent.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondary,
        side: const BorderSide(color: secondary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w900,
    color: textSecond,
    letterSpacing: 2.0,
  );
}
