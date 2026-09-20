import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- SmartEve Brand Color Palette ---
  static const Color primaryBlue = Color(0xFF4E6BEB); // Primary Blue
  static const Color deepNavy = Color(0xFF0B1220); // Deep Navy
  static const Color darkBlue = Color(0xFF111A33); // Dark Blue
  static const Color secondaryPurple = Color(0xFF7C5CFC); // Secondary Purple
  static const Color primaryPurple = secondaryPurple; // Backward compatibility alias
  static const Color accentBlue = Color(0xFF5B8CFF); // Accent Blue
  static const Color white = Color(0xFFFFFFFF); // White
  static const Color lightBackground = Color(0xFFF5F7FF); // Light Background
  static const Color cardBackground = Color(0xFFFFFFFF); // Card Background

  // Aliases for layout consistency
  static const Color background = lightBackground;
  static const Color surface = cardBackground;
  static const Color surfaceLight = Color(0xFFEDF2FF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color cyan = Color(0xFF0284C7);

  // --- Typography Colors ---
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // --- Status & Feedback ---
  static const Color success = Color(0xFF22C55E);
  static const Color liveGreen = success; // Backward compatibility alias
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningAmber = warning; // Backward compatibility alias
  static const Color error = Color(0xFFEF4444);
  static const Color dangerRose = error; // Backward compatibility alias
  static const Color alertRed = error;

  // --- Spacing Tokens (8px base unit) ---
  static const double space8 = 8.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // --- Border Radius Tokens ---
  static const double radiusCard = 8.0;
  static const double radiusButton = 12.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryPurple,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          labelSmall: TextStyle(color: textMuted),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
