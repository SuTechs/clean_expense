import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors extracted/approximated from the "clean" reference image
  // The image shows a very light, clean interface with distinct primary colors.
  // Assuming a purple/indigo accent based on "Sumit" avatar and clean lines.

  static const Color primaryColor = Color(0xFF6C63FF); // Example clean purple
  static const Color accentColor = Color(
    0xFF00C853,
  ); // Green for positive/income
  static const Color errorColor = Color(0xFFE53935); // Red for expense

  static const Color background = Color(
    0xFFF9FAFC,
  ); // Very light grey/white background
  static const Color surface = Colors.white;

  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color textLight = Color(0xFFFAFAFA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: surface,
        background: background,
        error: errorColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textGrey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
