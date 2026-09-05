import 'package:flutter/material.dart';
import 'adiuva_colors.dart';
import 'adiuva_spacing.dart';
import 'adiuva_radius.dart';
import 'adiuva_elevation.dart';
import 'adiuva_typography.dart';

/// ADIUVA Centralized Theme Builder
/// 
/// Material 3 Themes for:
/// - Light Mode
/// - Dark Mode
/// - High-Contrast Light Mode
/// - High-Contrast Dark Mode
class AdiuvaTheme {
  AdiuvaTheme._();

  /// Standard Light Theme (Verdant Teal & Slate)
  static ThemeData get lightTheme {
    final textTheme = AdiuvaTypography.createTextTheme(
      AdiuvaColors.lightTextPrimary,
      AdiuvaColors.lightTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AdiuvaColors.primaryTeal,
        onPrimary: AdiuvaColors.onPrimary,
        primaryContainer: AdiuvaColors.primaryContainer,
        onPrimaryContainer: AdiuvaColors.onPrimaryContainer,
        secondary: AdiuvaColors.voiceAmber,
        onSecondary: AdiuvaColors.onVoiceContainer,
        secondaryContainer: AdiuvaColors.voiceContainer,
        onSecondaryContainer: AdiuvaColors.onVoiceContainer,
        surface: AdiuvaColors.lightSurface,
        onSurface: AdiuvaColors.lightTextPrimary,
        error: AdiuvaColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AdiuvaColors.lightBackground,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AdiuvaColors.lightSurface,
        elevation: AdiuvaElevation.level1,
        shape: RoundedRectangleBorder(
          borderRadius: AdiuvaRadius.borderRadiusLg,
          side: const BorderSide(color: AdiuvaColors.lightBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AdiuvaColors.lightSurface,
        foregroundColor: AdiuvaColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdiuvaColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AdiuvaSpacing.lg,
          vertical: AdiuvaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AdiuvaColors.lightBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AdiuvaColors.lightBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AdiuvaColors.primaryTeal, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AdiuvaColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AdiuvaColors.error, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AdiuvaSpacing.minTouchTarget),
          backgroundColor: AdiuvaColors.primaryTeal,
          foregroundColor: AdiuvaColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AdiuvaRadius.borderRadiusMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AdiuvaSpacing.xl,
            vertical: AdiuvaSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AdiuvaSpacing.minTouchTarget),
          foregroundColor: AdiuvaColors.primaryTeal,
          side: const BorderSide(color: AdiuvaColors.primaryTeal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AdiuvaRadius.borderRadiusMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AdiuvaSpacing.xl,
            vertical: AdiuvaSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }

  /// Standard Dark Theme (Slate & Verdant Teal)
  static ThemeData get darkTheme {
    final textTheme = AdiuvaTypography.createTextTheme(
      AdiuvaColors.darkTextPrimary,
      AdiuvaColors.darkTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AdiuvaColors.primaryLight,
        onPrimary: AdiuvaColors.slate900,
        primaryContainer: AdiuvaColors.primaryDark,
        onPrimaryContainer: AdiuvaColors.primaryContainer,
        secondary: AdiuvaColors.voiceAmber,
        onSecondary: AdiuvaColors.slate900,
        surface: AdiuvaColors.darkSurface,
        onSurface: AdiuvaColors.darkTextPrimary,
        error: AdiuvaColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AdiuvaColors.darkBackground,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AdiuvaColors.darkSurface,
        elevation: AdiuvaElevation.level1,
        shape: RoundedRectangleBorder(
          borderRadius: AdiuvaRadius.borderRadiusLg,
          side: const BorderSide(color: AdiuvaColors.darkBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AdiuvaColors.darkSurface,
        foregroundColor: AdiuvaColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdiuvaColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AdiuvaSpacing.lg,
          vertical: AdiuvaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AdiuvaColors.darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AdiuvaColors.darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AdiuvaColors.primaryLight, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AdiuvaColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AdiuvaSpacing.minTouchTarget),
          backgroundColor: AdiuvaColors.primaryLight,
          foregroundColor: AdiuvaColors.slate900,
          shape: RoundedRectangleBorder(
            borderRadius: AdiuvaRadius.borderRadiusMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AdiuvaSpacing.xl,
            vertical: AdiuvaSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }

  /// High Contrast Light Theme (Black on White with thick borders)
  static ThemeData get highContrastLightTheme {
    final textTheme = AdiuvaTypography.createTextTheme(
      AdiuvaColors.hcLightTextPrimary,
      AdiuvaColors.hcLightTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AdiuvaColors.hcLightPrimary,
        onPrimary: Colors.white,
        secondary: AdiuvaColors.voiceAmberDark,
        onSecondary: Colors.black,
        surface: AdiuvaColors.hcLightSurface,
        onSurface: AdiuvaColors.hcLightTextPrimary,
        error: Color(0xFFB00020),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AdiuvaColors.hcLightBackground,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AdiuvaColors.hcLightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AdiuvaRadius.borderRadiusSm,
          side: const BorderSide(
            color: AdiuvaColors.hcLightBorder,
            width: AdiuvaElevation.hcBorderThick,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusSm,
          borderSide: const BorderSide(
            color: AdiuvaColors.hcLightBorder,
            width: AdiuvaElevation.hcBorderThick,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusSm,
          borderSide: const BorderSide(
            color: AdiuvaColors.hcLightBorder,
            width: AdiuvaElevation.hcBorderThick,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusSm,
          borderSide: const BorderSide(
            color: AdiuvaColors.hcLightPrimary,
            width: 3.0,
          ),
        ),
      ),
    );
  }

  /// High Contrast Dark Theme (White on Black with thick borders & cyan/yellow accents)
  static ThemeData get highContrastDarkTheme {
    final textTheme = AdiuvaTypography.createTextTheme(
      AdiuvaColors.hcDarkTextPrimary,
      AdiuvaColors.hcDarkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AdiuvaColors.hcDarkPrimary,
        onPrimary: Colors.black,
        secondary: AdiuvaColors.hcDarkAccentYellow,
        onSecondary: Colors.black,
        surface: AdiuvaColors.hcDarkSurface,
        onSurface: AdiuvaColors.hcDarkTextPrimary,
        error: Color(0xFFFF5252),
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: AdiuvaColors.hcDarkBackground,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AdiuvaColors.hcDarkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AdiuvaRadius.borderRadiusSm,
          side: const BorderSide(
            color: AdiuvaColors.hcDarkBorder,
            width: AdiuvaElevation.hcBorderThick,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusSm,
          borderSide: const BorderSide(
            color: AdiuvaColors.hcDarkBorder,
            width: AdiuvaElevation.hcBorderThick,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusSm,
          borderSide: const BorderSide(
            color: AdiuvaColors.hcDarkBorder,
            width: AdiuvaElevation.hcBorderThick,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AdiuvaRadius.borderRadiusSm,
          borderSide: const BorderSide(
            color: AdiuvaColors.hcDarkAccentYellow,
            width: 3.0,
          ),
        ),
      ),
    );
  }
}
