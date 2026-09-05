import 'package:flutter/material.dart';

/// ADIUVA Centralized Typography Tokens & TextTheme Builders
class AdiuvaTypography {
  AdiuvaTypography._();

  static const String primaryFontFamily = 'Inter';

  /// Text Theme for Light & Dark Mode
  static TextTheme createTextTheme(Color primaryTextColor, Color secondaryTextColor) {
    return TextTheme(
      // Display Styles (Large Hero Headers)
      displayLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        color: primaryTextColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.25,
        color: primaryTextColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: primaryTextColor,
      ),

      // Headline Styles (Page & Section Headers)
      headlineLarge: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: primaryTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryTextColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryTextColor,
      ),

      // Title Styles (Card Headers & Feature Titles)
      titleLarge: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryTextColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        height: 1.45,
        letterSpacing: 0.15,
        color: primaryTextColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        height: 1.45,
        letterSpacing: 0.1,
        color: primaryTextColor,
      ),

      // Body Styles (Main Paragraph & Content Text)
      bodyLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
        color: primaryTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.25,
        color: secondaryTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.4,
        color: secondaryTextColor,
      ),

      // Label Styles (Buttons, Chips, Badges)
      labelLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
        color: primaryTextColor,
      ),
      labelMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
        color: primaryTextColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
        color: secondaryTextColor,
      ),
    );
  }
}
