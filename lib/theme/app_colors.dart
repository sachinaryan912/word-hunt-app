import 'package:flutter/material.dart';

/// 2D Cartoon Color System & 2.5D Tactile UI Tokens
class AppColors {
  // Brand & Primary Color Family
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color primaryYellowBevel = Color(0xFFD97706);
  static const Color primaryOrange = Color(0xFFFF7D29);
  static const Color primaryOrangeBevel = Color(0xFFC2410C);
  
  static const Color royalBlue = Color(0xFF2563EB);
  static const Color royalBlueBevel = Color(0xFF1D4ED8);
  static const Color skyBlue = Color(0xFF38BDF8);
  static const Color skyBlueBevel = Color(0xFF0284C7);
  
  static const Color freshGreen = Color(0xFF22C55E);
  static const Color freshGreenBevel = Color(0xFF15803D);
  
  static const Color coral = Color(0xFFFF6B6B);
  static const Color coralBevel = Color(0xFFDC2626);
  
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleBevel = Color(0xFF6D28D9);

  // Backgrounds & Surface Canvas
  static const Color bgDarkNavy = Color(0xFF0F172A);
  static const Color bgSkyTint = Color(0xFFE0F2FE);
  static const Color bgCream = Color(0xFFFFFBEB);
  
  // Card & Panel Surfaces
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceCardDark = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF334155);
  static const Color surfaceBorder = Color(0xFFE2E8F0);
  static const Color surfaceBorderDark = Color(0xFF475569);

  // Text & Typography
  static const Color textPrimaryDark = Color(0xFF0F172A);
  static const Color textPrimaryLight = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF475569);
  static const Color textSecondaryLight = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gameplay & Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color markerYellow = Color(0xFFFFE066);
  static const Color markerGreen = Color(0xFF86EFAC);
  static const Color markerBlue = Color(0xFF93C5FD);
  static const Color markerPink = Color(0xFFF472B6);
  
  // Legacy Aliases for backwards compatibility
  static const Color background = bgDarkNavy;
  static const Color surface = surfaceCardDark;
  static const Color goldAccent = primaryYellow;
  static const Color goldHighlight = Color(0xFFFEF08A);
  static const Color goldSubtle = Color(0xFF451A03);
  static const Color goldGlow = Color(0x66FFC107);
  static const Color gold3DBorder = primaryYellowBevel;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color divider = Color(0xFF334155);
  static const Color cyanGlow = skyBlue;

  // 2.5D Shadow & Highlight Tokens
  static const Color shadowSoft = Color(0x33000000);
  static const Color shadowHard = Color(0x66000000);
  static const Color topHighlight = Color(0x40FFFFFF);
}

