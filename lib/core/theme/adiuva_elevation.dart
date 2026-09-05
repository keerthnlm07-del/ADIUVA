import 'package:flutter/material.dart';

/// ADIUVA Centralized Elevation & High Contrast Border Tokens
class AdiuvaElevation {
  AdiuvaElevation._();

  static const double none = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;
  static const double level4 = 8.0;
  static const double level5 = 12.0;

  // High Contrast Outline Thicknesses
  static const double hcBorderNormal = 2.0;
  static const double hcBorderThick = 3.0;

  // Soft subtle shadows for standard light mode
  static final List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}
