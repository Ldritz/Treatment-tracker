import 'package:flutter/material.dart';

class AppTheme {
  // Digital Curator / Vector Logic colors
  static const Color primary = Color(0xFF00459A);
  static const Color primaryContainer = Color(0xFF005CC8);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  
  static const Color secondary = Color(0xFF4A5E88);
  static const Color secondaryLight = Color(0xFFBBCFFF);
  static const Color secondaryDark = Color(0xFF32466F);

  static const Color background = Color(0xFFF7F9FF);
  static const Color surface = Color(0xFFF7F9FF);
  static const Color surfaceLow = Color(0xFFF1F4FA);
  static const Color surfaceHighest = Color(0xFFDFE3E8);
  static const Color surfaceLowest = Color(0xFFFFFFFF);

  static const Color text = Color(0xFF181C20);
  static const Color textMuted = Color(0xFF424753);
  static const Color textDark = Color(0xFF181C20);
  
  static const Color border = Color(0xFFDFE3E8); // mapped to surfaceHighest
  static const Color error = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: text),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: text),
        displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: text),
        bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: text),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: text),
        bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        backgroundColor: surfaceLowest,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF38BDF8),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38BDF8),
        secondary: Color(0xFF94A3B8),
        surface: Color(0xFF1E293B),
        error: Color(0xFFF43F5E),
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.9)),
        bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.6)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF38BDF8),
        unselectedItemColor: Color(0xFF94A3B8),
        backgroundColor: Color(0xFF1E293B),
        elevation: 8,
      ),
    );
  }

  static ThemeData get themeData => lightTheme;
}
