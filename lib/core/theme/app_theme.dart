import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant Leaf / Emerald Green palette (from grocery UI design)
  static const primaryColor = Color(0xFF23AA49);
  static const primaryDark = Color(0xFF1B8A3A);
  static const primaryLight = Color(0xFFEBF8EE);
  static const secondaryColor = Color(0xFF10B981);
  static const accentColor = Color(0xFFF59E0B);

  // Neutral tones - Light mode
  static const lightBackground = Color(0xFFF9FAFB);
  static const lightSurface = Colors.white;
  static const lightBorder = Color(0xFFF1F5F9);
  static const lightBorderStrong = Color(0xFFE2E8F0);
  static const lightOnSurface = Color(0xFF0F172A);
  static const lightSubtext = Color(0xFF64748B);

  // Neutral tones - Dark mode
  static const darkBackground = Color(0xFF0B132B);
  static const darkSurface = Color(0xFF131D38);
  static const darkBorder = Color(0xFF1E293B);
  static const darkBorderStrong = Color(0xFF334155);
  static const darkOnSurface = Color(0xFFF8FAFC);
  static const darkSubtext = Color(0xFF94A3B8);

  static final ThemeData lightTheme = _buildLightTheme();
  static final ThemeData darkTheme = _buildDarkTheme();

  static const String fontFamily = 'GoogleSans';
  static const List<String> fontFallbacks = ['GoogleSans', 'Google Sans'];

  static ThemeData _buildLightTheme() {
    final baseTextTheme = ThemeData.light().textTheme.apply(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallbacks,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallbacks,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: lightOnSurface,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.2,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          color: lightOnSurface,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.2,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: lightOnSurface,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.25,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: lightOnSurface,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.3,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: lightOnSurface,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.3,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: lightOnSurface,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.35,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: lightSubtext,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.35,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: lightSubtext,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.35,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
        ),
      ),
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        surface: lightSurface,
        onSurface: lightOnSurface,
        error: Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      dividerColor: lightBorderStrong,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: lightOnSurface),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          color: lightOnSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: lightBorderStrong, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFallbacks,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          color: Color(0xFF94A3B8),
          fontSize: 14,
          letterSpacing: 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorderStrong, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorderStrong, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final baseTextTheme = ThemeData.dark().textTheme.apply(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallbacks,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallbacks,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: darkOnSurface,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.2,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          color: darkOnSurface,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.2,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: darkOnSurface,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.25,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: darkOnSurface,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.3,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: darkOnSurface,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.3,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: darkOnSurface,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.35,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: darkSubtext,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.35,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: darkSubtext,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
          height: 1.35,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          letterSpacing: 0,
        ),
      ),
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: Color(0xFF1A3D2A),
        secondary: secondaryColor,
        surface: darkSurface,
        onSurface: darkOnSurface,
        error: Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: darkBorderStrong,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkOnSurface),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          color: darkOnSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: darkBorderStrong, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFallbacks,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallbacks,
          color: Color(0xFF64748B),
          fontSize: 14,
          letterSpacing: 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorderStrong, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorderStrong, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
      ),
    );
  }
}
