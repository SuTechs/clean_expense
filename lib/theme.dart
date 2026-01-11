import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // 1. Static Color Palette
  // ---------------------------------------------------------------------------

  // Primary Brand Colors

  // Used for headings, active tabs
  static const Color primaryNavy = Color(0xFF2D3250);

  // The specific "Finance Success" green
  static const Color primaryGreen = Color(0xFF2ECC71);

  // Used for "Food & Drinks" tag/buttons
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color accentPurple = Color(0xFF6C63FF);

  // Backgrounds

  // Very light grey/blue tint
  static const Color scaffoldBackground = Color(0xFFF8F9FB);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Search bar background
  static const Color inputFill = Color(0xFFF0F2F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1C29); // Almost black
  static const Color textSecondary = Color(0xFF9095A1); // Grey text
  static const Color textWhite = Color(0xFFFFFFFF);

  // Functional Colors
  static const Color dangerRed = Color(0xFFEB5757); // For "Abort" or errors
  static const Color dividerColor = Color(0xFFEDEEF2);

  // Other Colors
  static const Color tagBackground = Color(0xFFEAEBF0); // Cool light grey
  static const Color tagText = Color(0xFF7D8294); // Muted slate grey

  // Gradients (for that Graph)
  static const LinearGradient greenGraphGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2ECC71), // Green
      Color(0x002ECC71), // Transparent Green
    ],
  );

  // ---------------------------------------------------------------------------
  // 2. Theme Data Generator
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Base Colors
      scaffoldBackgroundColor: scaffoldBackground,
      primaryColor: primaryNavy,

      // Color Scheme (Material 3 definition)
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        secondary: primaryGreen,
        surface: cardBackground,
        error: dangerRed,
        onPrimary: textWhite,
        onSurface: textPrimary,
      ),

      // Typography (Using Inter to match the clean look)
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBackground,
        // Blends with body
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme (for the white blocks)
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.transparent), // Clean look
        ),
      ),

      // Input Decoration (Search bars, etc.)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryNavy, width: 1),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryNavy,
        foregroundColor: textWhite,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textPrimary, size: 24),
    );
  }
}
