import 'package:flutter/material.dart';

class AppTheme {
  // UI UX Pro Max - Vibrant & Block-based Light Theme
  // Note: We are keeping the old variable names to instantly reskin the app without breaking screen files.
  
  static const Color pureWhite = Color(0xFF450A0A); // Old White Text -> New Dark Foreground
  static const Color pureBlack = Color(0xFFFFFFFF); // Old Black -> New White
  
  // Backgrounds
  static const Color bgDarkCharcoal = Color(0xFFFEF2F2); // Old Dark Bg -> New Warm Light Red
  static const Color bgDarkPanel = Color(0xFFFFFFFF); // Old Panel -> New White Block Surface
  static const Color bgDeepBurgundy = Color(0xFFFECACA); // Old Secondary Dark -> New Muted Border Red
  
  // Accents
  static const Color primaryGold = Color(0xFFDC2626); // Old Gold -> New Primary Red
  static const Color primaryBurgundy = Color(0xFFF87171); // Old Burgundy -> New Secondary Light Red
  
  // Text
  static const Color textLight = Color(0xFF450A0A); // Old Light Text -> New Dark Foreground
  static const Color textMuted = Color(0xFF991B1B); // Old Muted -> New Medium Red
  static const Color textGold = Color(0xFFA16207); // Old Gold -> New Warm Gold CTA
  
  // Borders
  static const Color borderGold = Color(0x33DC2626); // Primary with alpha
  static const Color borderLight = Color(0xFFFECACA); // Border color
  
  // Status (Chef's Tags)
  static const Color vegGreen = Color(0xFF166534); // Dark green for light background
  static const Color nonVegRed = Color(0xFF991B1B); // Dark red for light background
  
  // The global app theme data
  static ThemeData get luxuryTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgDarkCharcoal,
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.light(
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
          foregroundColor: pureBlack,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
