import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primaryBlue = Color(0xFF4A90FF);
  static const Color primaryDark = Color(0xFF2D5FCC);
  static const Color primaryLight = Color(0xFF7BB3FF);

  // Secondary Colors
  static const Color secondaryPurple = Color(0xFF7C3AED);
  static const Color secondaryPink = Color(0xFFEC4899);
  static const Color secondaryTeal = Color(0xFF14B8A6);

  // Accent Colors (from UI design)
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF97316);

  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey900 = Color(0xFF111827);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey50 = Color(0xFFFAFAFA);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFCD34D);
  static const Color info = Color(0xFF3B82F6);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Accessibility Colors (for different visibility modes)
  static const Color highContrastBlack = Color(0xFF000000);
  static const Color highContrastWhite = Color(0xFFFFFFFF);

  // Disabled State
  static const Color disabled = Color(0xFFCBD5E1);
  static const Color disabledText = Color(0xFF94A3B8);

  // Borders
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF475569);

  // Gradient Colors (for visual appeal)
  static const List<Color> primaryGradient = [
    Color(0xFF4A90FF),
    Color(0xFF7C3AED),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF06B6D4),
    Color(0xFF10B981),
  ];

  // Dark Mode Support
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? backgroundDark : backgroundLight;
  }

  static Color getSurfaceColor(bool isDarkMode) {
    return isDarkMode ? surfaceDark : surfaceLight;
  }

  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? white : black;
  }

  static Color getSubtleTextColor(bool isDarkMode) {
    return isDarkMode ? grey400 : grey600;
  }

  static Color getBorderColor(bool isDarkMode) {
    return isDarkMode ? borderDark : borderLight;
  }
}