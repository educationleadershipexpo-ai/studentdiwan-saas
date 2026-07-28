import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand color palette — matches desktop web app (Diwan purple/pink)
  static const Color primary = Color(0xFF9B59E6); // Diwan Purple — web #9B59E6
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFB490F5);
  static const Color primaryExtraLight = Color(0xFFF3E9FE);
  static const Color primarySurface = Color(0xFFFAF5FF);

  static const Color secondary = Color(0xFFE8459B); // Diwan Pink accent — web #E8459B

  // Neutral colors
  static const Color background = Color(0xFFF8F7FF);
  static const Color surface = Colors.white;
  static const Color text1 = Color(0xFF1A1A1A);
  static const Color text2 = Color(0xFF4A4A5A);
  static const Color text3 = Color(0xFF8A8AA0);

  // Dark-mode neutrals — deep near-black surfaces that keep the Diwan purple
  // readable. Used by AppTheme.dark; screens that hardcode AppColors.surface /
  // background still render, but dark-aware screens should prefer
  // Theme.of(context).colorScheme where possible.
  static const Color darkBackground = Color(0xFF0E0E16); // matches web #0E0E16
  static const Color darkSurface = Color(0xFF1F1F38);   // matches web #1F1F38
  static const Color darkText1 = Color(0xFFF5F3FA);
  static const Color darkText2 = Color(0xFFC7C3D4);
  static const Color darkText3 = Color(0xFF8E8AA0);

  // Semantic status colors
  static const Color green = Color(0xFF10B981); // Present
  static const Color greenLight = Color(0xFFD1FAE5);

  static const Color amber = Color(0xFFF59E0B); // Late / Pending
  static const Color amberLight = Color(0xFFFEF3C7);

  static const Color red = Color(0xFFEF4444); // Absent / Urgent
  static const Color redLight = Color(0xFFFEE2E2);

  static const Color purple = Color(0xFF9B59E6); // Leave / Exam
  static const Color purpleLight = Color(0xFFF3E9FE);

  static const Color blue = Color(0xFF38BDF8);
  static const Color blueLight = Color(0xFFE0F2FE);

  // Gradients — matches desktop web hero gradient (pink → purple)
  static const List<Color> primaryGradient = [Color(0xFFE11D74), Color(0xFF9333EA)];
  static const List<Color> headerGradient = [Color(0xFF7C3AED), Color(0xFF9B59E6)];
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.inter(
          color: AppColors.text1,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.text1,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.text2,
          fontSize: 13,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        labelStyle: const TextStyle(color: AppColors.text2, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.text3, fontSize: 13),
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
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primaryExtraLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.inter(
          color: AppColors.darkText1,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.darkText1,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.darkText2,
          fontSize: 13,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF322F3D), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF322F3D), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.darkText2, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.darkText3, fontSize: 13),
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
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: Color(0xFF322F3D), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ── Dark-aware color helpers ─────────────────────────────────────────────────
// Use these wherever screens currently hardcode AppColors.background / Colors.white.
// They read brightness from the nearest Theme, so they react to themeModeProvider.
extension AppDarkColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Page / scaffold backgrounds
  Color get bgColor     => isDark ? AppColors.darkBackground : AppColors.background;
  // Card / surface backgrounds
  Color get cardColor   => isDark ? AppColors.darkSurface    : Colors.white;
  // Subtle section background (just above card)
  Color get surfaceTint => isDark ? const Color(0xFF252540)  : AppColors.primarySurface;
  // Border / divider
  Color get borderColor => isDark ? const Color(0xFF322F3D)  : AppColors.primaryExtraLight;
  // Text
  Color get t1          => isDark ? AppColors.darkText1      : AppColors.text1;
  Color get t2          => isDark ? AppColors.darkText2      : AppColors.text2;
  Color get t3          => isDark ? AppColors.darkText3      : AppColors.text3;
  // Skeleton shimmer
  Color get skeletonBase      => isDark ? const Color(0xFF252540) : const Color(0xFFE2E8F0);
  Color get skeletonHighlight => isDark ? const Color(0xFF2E2E52) : const Color(0xFFF1F5F9);
  // Icon tint inside colored tiles
  Color get iconTileBg  => isDark ? const Color(0xFF252540)  : AppColors.primaryExtraLight;
}

extension TextThemeHelpers on BuildContext {
  TextStyle get heading1 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: t1,
        height: 1.2,
      );

  TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: t1,
        height: 1.2,
      );

  TextStyle get heading3 => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: t1,
      );

  TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13.5,
        color: t2,
        height: 1.4,
      );

  TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        color: t3,
      );
}
