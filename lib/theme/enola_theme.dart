import 'package:flutter/material.dart';

class EnolaTheme {
  EnolaTheme._();

  // ── Energetic & Scholarly Palette ──────────────────────────────────────
  static const Color background  = Color(0xFFFCFBF7); // Brighter, cleaner paper
  static const Color surface     = Color(0xFFF7F5F0); // Subtle warmth
  static const Color surfaceHigh = Color(0xFFEFEDE6); 
  
  // Higher energy colors
  static const Color accent      = Color(0xFFF59E0B); // Vibrant Amber/Gold (More "Magic")
  static const Color secondary   = Color(0xFF0EA5E9); // Sky Blue (For discovery/info)
  static const Color accentSoft  = Color(0x26F59E0B); // 15% Opacity Amber
  
  static const Color textPrimary = Color(0xFF1E1B16); // High contrast near-black
  static const Color textSecond  = Color(0xFF5D5950); // Cleaner slate
  
  static const Color correct     = Color(0xFF10B981); // Emerald green (Energetic)
  static const Color wrong       = Color(0xFFEF4444); // Sharp ruby red
  static const Color border      = Color(0xFFE5E2D9);

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
        fontFamily: 'Serif', // Ensure you have a serif font or use GoogleFonts
        fontSize: 32,
        fontWeight: FontWeight.w800, // Thicker for more energy
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
      elevation: 0, // Flat with border looks more modern/scholarly
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Rounder for friendlier feel
        borderSide: const BorderSide(color: border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4, // Add shadow for "pressable" energy
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
