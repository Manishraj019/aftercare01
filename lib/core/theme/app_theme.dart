import 'package:flutter/material.dart';

class AppTheme {
  // Luxury Dark Theme Colors
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  
  // Backgrounds
  static const Color bgDarkCharcoal = Color(0xFF0C0C0C);
  static const Color bgDarkPanel = Color(0xFF141414);
  static const Color bgDeepBurgundy = Color(0xFF23080F); 
  
  // Accents
  static const Color primaryGold = Color(0xFFD4AF37); // Brass/Gold
  static const Color primaryBurgundy = Color(0xFF4A1220); // Oxblood
  
  // Text
  static const Color textLight = Color(0xFFF0F0F0);
  static const Color textMuted = Color(0xFFA0A0A0);
  static const Color textGold = Color(0xFFE8D08B);

  // Borders
  static const Color borderGold = Color(0x33D4AF37);
  static const Color borderLight = Color(0x1AFFFFFF);

  // Status (Chef's Tags)
  static const Color vegGreen = Color(0xFF2E7D32);
  static const Color nonVegRed = Color(0xFFC62828);
  
  // The global app theme data
  static ThemeData get luxuryTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDarkCharcoal,
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: primaryBurgundy,
        surface: bgDarkPanel,
        onSurface: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDarkCharcoal,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: primaryGold),
      ),
      iconTheme: const IconThemeData(color: primaryGold),
      textTheme: const TextTheme(
        // Playfair Display will be used via GoogleFonts inline, but setting baseline colors
        displayLarge: TextStyle(color: textLight),
        displayMedium: TextStyle(color: textLight),
        displaySmall: TextStyle(color: textLight),
        headlineLarge: TextStyle(color: textLight),
        headlineMedium: TextStyle(color: textLight),
        headlineSmall: TextStyle(color: textLight),
        titleLarge: TextStyle(color: textLight),
        titleMedium: TextStyle(color: textLight),
        titleSmall: TextStyle(color: textLight),
        bodyLarge: TextStyle(color: textLight),
        bodyMedium: TextStyle(color: textLight),
        bodySmall: TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: bgDarkCharcoal,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGold,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: bgDarkPanel,
        contentTextStyle: TextStyle(color: textLight),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent, // Transparent for Glassmorphism
        elevation: 0,
      ),
    );
  }
}
