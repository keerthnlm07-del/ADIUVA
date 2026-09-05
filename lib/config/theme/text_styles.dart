import 'package:flutter/material.dart';
import '../../core/theme/adiuva_typography.dart';

/// Legacy TextStyles helper forwarding to AdiuvaTypography
class TextStyles {
  TextStyles._();

  static TextTheme textTheme(Color primaryColor, Color secondaryColor) {
    return AdiuvaTypography.createTextTheme(primaryColor, secondaryColor);
  }
}
