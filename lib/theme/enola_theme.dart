import 'package:flutter/material.dart';

class EnolaTheme {
  EnolaTheme._();

  // ── Palette (Light & Enjoyable) ──────────────────────────────────────────
  static const Color background  = Color(0xFFFDFCF8); // Soft "Paper" white
  static const Color surface     = Color(0xFFF2F0E9); // Slightly darker wash
  static const Color surfaceHigh = Color(0xFFEBE8DF); 
  static const Color accent      = Color(0xFFC59D1E); // Slightly deeper gold for readability
  static const Color accentSoft  = Color(0x1AC59D1E); 
  static const Color textPrimary = Color(0xFF2D2C29); // Deep Charcoal (easier on eyes than #000)
  static const Color textSecond  = Color(0xFF6B6964); // Muted slate gray
  static const Color correct     = Color(0xFF388E3C); // Adjusted for light background
  static const Color wrong       = Color(0xFFD32F2F);
  static const Color border      = Color(0xFFE0DDD5);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: accent,
      secondary: accent,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Serif', // Keeps that "Enola" aesthetic
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: textSecond, height: 1.5),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2, // Small shadow for depth in light mode
      shadowColor: border.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecond),
    ),
  );
}
