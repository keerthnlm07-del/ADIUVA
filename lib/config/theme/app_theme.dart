import 'package:flutter/material.dart';
import '../../core/theme/adiuva_theme.dart';

/// Legacy AppTheme export forwarding to AdiuvaTheme
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => AdiuvaTheme.lightTheme;
  static ThemeData get darkTheme => AdiuvaTheme.darkTheme;
  static ThemeData get highContrastLightTheme => AdiuvaTheme.highContrastLightTheme;
  static ThemeData get highContrastDarkTheme => AdiuvaTheme.highContrastDarkTheme;
}
