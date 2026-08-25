import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  /// Transparent, light-icon system bars matching the app's dark navy
  /// background. Applied both at launch (see main.dart) and via
  /// [darkTheme]'s appBarTheme below — without the latter, Flutter's
  /// built-in AppBar silently forces the Android navigation bar to solid
  /// black on any screen that has one, and that black bar then persists
  /// even after navigating back to a screen without an AppBar.
  static const SystemUiOverlayStyle systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.outfitTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.bgDarkNavy,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surfaceCardDark,
        onSurface: AppColors.textPrimaryLight,
        primary: AppColors.primaryYellow,
        onPrimary: AppColors.bgDarkNavy,
        secondary: AppColors.royalBlue,
        onSecondary: AppColors.textPrimaryLight,
        outline: AppColors.surfaceBorderDark,
        error: AppColors.error,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: GoogleFonts.fredoka(
          color: AppColors.textPrimaryLight,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        headlineMedium: GoogleFonts.fredoka(
          color: AppColors.textPrimaryLight,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        headlineSmall: GoogleFonts.fredoka(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.nunito(
          color: AppColors.textPrimaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: GoogleFonts.nunito(
          color: AppColors.textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: AppColors.textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: AppColors.textSecondaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.nunito(
          color: AppColors.textPrimaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: systemOverlayStyle,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight, size: 22),
        titleTextStyle: GoogleFonts.fredoka(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCardDark,
        elevation: 4,
        shadowColor: AppColors.shadowSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorderDark, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.bgDarkNavy,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.primaryYellowBevel, width: 2),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          side: const BorderSide(color: AppColors.surfaceBorderDark, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

