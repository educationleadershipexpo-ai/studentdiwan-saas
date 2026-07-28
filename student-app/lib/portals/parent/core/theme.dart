import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Diwan Parent Portal · Color System ───────────────────────────────────────
// Palette: matches desktop web app (Diwan purple #9B59E6 + pink #E8459B accent)
class AppColors {
  static const primary         = Color(0xFF9B59E6);   // Diwan Purple — web #9B59E6
  static const primaryLight    = Color(0xFFB490F5);   // Soft Purple
  static const primaryExtraLight = Color(0xFFF3E9FE); // Ice Purple tint
  static const primarySurface  = Color(0xFFFAF5FF);   // Near-white purple

  static const background      = Color(0xFFF8F7FF);   // Desktop background
  static const card            = Color(0xFFFFFFFF);

  static const text1           = Color(0xFF1A1A1A);   // Desktop foreground
  static const text2           = Color(0xFF4A4A5A);   // Slate
  static const text3           = Color(0xFF8A8AA0);   // Cool Gray

  // Dark-mode neutrals
  static const darkBackground  = Color(0xFF0E0E16);
  static const darkSurface     = Color(0xFF1F1F38);
  static const darkText1       = Color(0xFFF5F3FA);
  static const darkText2       = Color(0xFFC7C3D4);
  static const darkText3       = Color(0xFF8E8AA0);

  static const green           = Color(0xFF10B981);   // Emerald
  static const greenLight      = Color(0xFFD1FAE5);
  static const amber           = Color(0xFFF59E0B);   // Golden Amber accent
  static const amberLight      = Color(0xFFFEF3C7);
  static const red             = Color(0xFFEF4444);
  static const redLight        = Color(0xFFFEE2E2);
  static const blue            = Color(0xFF38BDF8);   // Sky Blue (info/secondary)
  static const blueLight       = Color(0xFFE0F2FE);

  // Gradients — matches desktop web hero gradient (pink → purple)
  static const List<Color> primaryGradient = [Color(0xFFE11D74), Color(0xFF9333EA)];
  static const List<Color> cardGradient    = [Color(0xFF9B59E6), Color(0xFFB490F5)];
  static const List<Color> headerGradient  = [Color(0xFF7C3AED), Color(0xFF9B59E6)];
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: const Color(0xFFE8459B),
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.darkText1,
        displayColor: AppColors.darkText1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.darkText1),
        iconTheme: const IconThemeData(color: AppColors.darkText1),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF322F3D), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF322F3D), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryLight, width: 2)),
        labelStyle: GoogleFonts.inter(color: AppColors.darkText3, fontSize: 14, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w700),
        hintStyle: GoogleFonts.inter(color: AppColors.darkText3, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.darkText3,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerColor: const Color(0xFF322F3D),
    );
  }

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
          borderSide: const BorderSide(color: AppColors.primaryExtraLight, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryExtraLight, width: 1.5),
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

// ── Dark-aware color helpers ──────────────────────────────────────────────────
extension AppDarkColors on BuildContext {
  bool get isDark         => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor       => isDark ? AppColors.darkBackground : AppColors.background;
  Color get cardColor     => isDark ? AppColors.darkSurface    : AppColors.card;
  Color get surfaceTint   => isDark ? const Color(0xFF252540)  : AppColors.primarySurface;
  Color get borderColor   => isDark ? const Color(0xFF322F3D)  : AppColors.primaryExtraLight;
  Color get t1            => isDark ? AppColors.darkText1      : AppColors.text1;
  Color get t2            => isDark ? AppColors.darkText2      : AppColors.text2;
  Color get t3            => isDark ? AppColors.darkText3      : AppColors.text3;
  Color get skeletonBase  => isDark ? const Color(0xFF252540)  : const Color(0xFFE2E8F0);
  Color get skeletonHighlight => isDark ? const Color(0xFF2E2E52) : const Color(0xFFF1F5F9);
  Color get iconTileBg    => isDark ? const Color(0xFF252540)  : AppColors.primaryExtraLight;
}

// ── Text Style Helpers ────────────────────────────────────────────────────────
extension AppTextStyles on BuildContext {
  TextStyle get heading1  => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: t1, letterSpacing: -0.4);
  TextStyle get heading2  => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: t1);
  TextStyle get heading3  => GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: t1);
  TextStyle get body      => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: t2);
  TextStyle get bodySmall => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: t3);
  TextStyle get label     => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: t3, letterSpacing: 0.6, height: 1);
  TextStyle get stat      => GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: t1);
}
