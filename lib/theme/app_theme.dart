import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFFE91E63); // Pink
  static const Color primaryLight = Color(0xFFFCE4EC); // Pink.shade50
  static const Color secondary = Color(0xFF4CAF50); // Green
  static const Color background = Color(0xFFF8F9FA); // Off-white
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF9094A6);

  static TextTheme _applyFallback(TextTheme baseTheme) {
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      displayMedium: baseTheme.displayMedium?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      displaySmall: baseTheme.displaySmall?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      headlineLarge: baseTheme.headlineLarge?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      headlineMedium: baseTheme.headlineMedium?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      headlineSmall: baseTheme.headlineSmall?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      titleLarge: baseTheme.titleLarge?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      titleMedium: baseTheme.titleMedium?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      titleSmall: baseTheme.titleSmall?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      bodyLarge: baseTheme.bodyLarge?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      bodyMedium: baseTheme.bodyMedium?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      bodySmall: baseTheme.bodySmall?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      labelLarge: baseTheme.labelLarge?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      labelMedium: baseTheme.labelMedium?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      labelSmall: baseTheme.labelSmall?.copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      textTheme: _applyFallback(GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w700),
        displaySmall: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: GoogleFonts.outfit(color: textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.outfit(color: textSecondary, fontSize: 14),
        labelLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      )),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 15).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
        labelStyle: GoogleFonts.outfit(color: textSecondary).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
