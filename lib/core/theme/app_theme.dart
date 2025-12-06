import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Futuristic Palette: Green, White, Blue
  static const Color primaryColor = Color(0xFF00FF94); // Neon Green
  static const Color secondaryColor = Color(0xFF00E5FF); // Electric Cyan/Blue
  static const Color accentColor = Color(0xFFFFFFFF); // Pure White
  
  static const Color backgroundColor = Color(0xFF0D1117); // Dark Futuristic Base
  static const Color surfaceColor = Color(0xFF161B22); // Slightly Lighter Surface
  
  static const Color errorColor = Color(0xFFFF3B30);

  static final ThemeData futuristicTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black, // Dark text on bright cyan
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 8,
        shadowColor: primaryColor.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // 3D & Gradient Effects
  static const BoxShadow neonShadow = BoxShadow(
    color: primaryColor,
    blurRadius: 15,
    spreadRadius: -2,
    offset: Offset(0, 4),
  );
  
  static BoxShadow glassShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.3),
    blurRadius: 20,
    spreadRadius: 2,
    offset: const Offset(0, 8),
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF0D1117), // Dark Base
      Color(0xFF1A1F2C), // Slightly Blue-ish Dark
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
