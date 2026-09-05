import 'package:flutter/material.dart';

/// ADIUVA Centralized Color Tokens
/// 
/// Palette hierarchy based on the ADIUVA Design System:
/// - Primary: Verdant Teal (#0D9488)
/// - Voice & Action: Sand / Amber (#F59E0B)
/// - Neutrals: Slate (#0F172A to #F8FAFC)
/// - High Contrast Mode overrides
class AdiuvaColors {
  AdiuvaColors._();

  // Primary Palette — Verdant Teal
  static const Color primaryTeal = Color(0xFF0D9488);        // Teal 600
  static const Color primaryLight = Color(0xFF14B8A6);       // Teal 500
  static const Color primaryDark = Color(0xFF0F766E);        // Teal 700
  static const Color primaryContainer = Color(0xFFCCFBF1);   // Teal 100
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF042F2E); // Teal 950

  // Voice & Action Palette — Sand / Amber
  static const Color voiceAmber = Color(0xFFF59E0B);         // Amber 500 (Voice Pulsing / Active)
  static const Color voiceAmberDark = Color(0xFFD97706);     // Amber 600
  static const Color voiceContainer = Color(0xFFFEF3C7);     // Amber 100
  static const Color onVoiceContainer = Color(0xFF78350F);   // Amber 900
  static const Color voiceWaveformPulse = Color(0xFFFFB74D); // Amber 300

  // Slate Neutral Palette
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Surface & Background — Light Mode
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Surface & Background — Dark Mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF475569);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // High Contrast — Light Mode (Black on White with thick borders)
  static const Color hcLightBackground = Color(0xFFFFFFFF);
  static const Color hcLightSurface = Color(0xFFFFFFFF);
  static const Color hcLightTextPrimary = Color(0xFF000000);
  static const Color hcLightBorder = Color(0xFF000000);
  static const Color hcLightPrimary = Color(0xFF004D40);

  // High Contrast — Dark Mode (White on Black with bright accents)
  static const Color hcDarkBackground = Color(0xFF000000);
  static const Color hcDarkSurface = Color(0xFF000000);
  static const Color hcDarkTextPrimary = Color(0xFFFFFFFF);
  static const Color hcDarkBorder = Color(0xFFFFFFFF);
  static const Color hcDarkPrimary = Color(0xFF80CBC4);
  static const Color hcDarkAccentYellow = Color(0xFFFFD700);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444);   // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6);    // Blue 500
}
