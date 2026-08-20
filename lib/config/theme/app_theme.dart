import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'text_styles.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme for the application
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.light,
        primary: AppColors.primaryBlue,
        secondary: AppColors.secondaryPurple,
        tertiary: AppColors.secondaryTeal,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),

      // Scaffolding
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.white,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.buttonText,
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      // Input Field Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: AppColors.grey500,
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.grey700,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.error,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 1,
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.black),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.black),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: AppColors.black),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.black),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.black),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.black),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.grey900),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.grey900),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.grey700),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey900),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryBlue),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.grey700),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.grey600),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.grey700,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        thickness: 1,
        space: 8,
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(AppColors.primaryBlue),
        checkColor: MaterialStateProperty.all(AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(AppColors.primaryBlue),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.grey400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue.withOpacity(0.5);
          }
          return AppColors.grey300;
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
        linearMinHeight: 4,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        disabledColor: AppColors.grey200,
        selectedColor: AppColors.primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.grey900,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primaryBlue.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.all(
          AppTextStyles.labelSmall.copyWith(
            color: AppColors.grey700,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(
              color: AppColors.primaryBlue,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.grey600,
            size: 24,
          );
        }),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey900,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.grey900,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.white,
        ),
      ),
    );
  }

  /// Dark theme for the application
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryPurple,
        tertiary: AppColors.secondaryTeal,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),

      // Scaffolding
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.grey900,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.white,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.buttonText,
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      // Input Field Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey800,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.borderDark,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.borderDark,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: AppColors.grey500,
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.grey300,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.error,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.grey800,
        elevation: 1,
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.grey800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.grey800,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.white),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.white),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: AppColors.white),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.white),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.white),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.grey100),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.grey100),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.grey200),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.grey300),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey100),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey300),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryLight),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.grey300),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.grey300,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.grey700,
        thickness: 1,
        space: 8,
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(AppColors.primaryLight),
        checkColor: MaterialStateProperty.all(AppColors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(AppColors.primaryLight),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.grey600;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryLight.withOpacity(0.5);
          }
          return AppColors.grey700;
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearMinHeight: 4,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey700,
        disabledColor: AppColors.grey800,
        selectedColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.grey900,
        indicatorColor: AppColors.primaryLight.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.all(
          AppTextStyles.labelSmall.copyWith(
            color: AppColors.grey400,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(
              color: AppColors.primaryLight,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.grey500,
            size: 24,
          );
        }),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey100,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.black,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.black,
        ),
      ),
    );
  }
}