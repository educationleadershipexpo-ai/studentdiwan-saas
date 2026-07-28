import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Diwan Teacher Portal · Color System ──────────────────────────────────────
// Palette: Royal Violet/Purple + Amber + Slate
class AppColors {
  static const primary          = Color(0xFF9810FA);   // Diwan Purple
  static const primaryLight     = Color(0xFFB564F7);   // Soft Purple
  static const primaryExtraLight = Color(0xFFF3E9FE);  // Ice Purple tint
  static const primarySurface   = Color(0xFFFAF5FF);   // Near-white purple

  static const background       = Color(0xFFF8F7FF);   // Desktop background
  static const card             = Color(0xFFFFFFFF);

  static const text1            = Color(0xFF1A1A1A);   // Desktop foreground
  static const text2            = Color(0xFF4A4A5A);   // Slate
  static const text3            = Color(0xFF8A8AA0);   // Cool Gray

  static const green            = Color(0xFF10B981);   // Emerald
  static const greenLight       = Color(0xFFD1FAE5);
  static const amber            = Color(0xFFF59E0B);   // Amber
  static const amberLight       = Color(0xFFFEF3C7);
  static const red              = Color(0xFFEF4444);   // Crimson Red
  static const redLight         = Color(0xFFFEE2E2);
  static const blue             = Color(0xFF3B82F6);   // Info/Secondary Blue
  static const blueLight        = Color(0xFFEBF2FF);
  static const orange           = Color(0xFFF97316);   // Late Orange
  static const orangeLight      = Color(0xFFFFEDD5);

  // Gradients — desktop hero gradient (135deg pink -> purple)
  static const List<Color> primaryGradient = [Color(0xFFD12386), Color(0xFF9810FA)];
  static const List<Color> cardGradient    = [Color(0xFF9810FA), Color(0xFFB564F7)];
  static const List<Color> headerGradient  = [Color(0xFF7A0DC8), Color(0xFF9810FA)]; // Premium dark purple gradient
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.card,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.text1,
        displayColor: AppColors.text1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.text1,
        ),
        iconTheme: const IconThemeData(color: AppColors.text1),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: AppColors.primary.withOpacity(0.08),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DCF7), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DCF7), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.text3, fontSize: 14, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
        hintStyle: GoogleFonts.inter(color: AppColors.text3, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.text3,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ── Text Style Helpers ────────────────────────────────────────────────────────
extension AppTextStyles on BuildContext {
  TextStyle get heading1 => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text1, letterSpacing: -0.4);
  TextStyle get heading2 => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text1);
  TextStyle get heading3 => GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1);
  TextStyle get body     => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text2);
  TextStyle get bodySmall => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text3);
  TextStyle get label    => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.6, height: 1);
  TextStyle get stat     => GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text1);
}
