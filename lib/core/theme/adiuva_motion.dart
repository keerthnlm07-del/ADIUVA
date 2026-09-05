import 'package:flutter/material.dart';

/// ADIUVA Centralized Animation & Motion Tokens
/// 
/// Automatically respects system animations disabled / reduced motion settings.
class AdiuvaMotion {
  AdiuvaMotion._();

  static const Duration durationInstant = Duration.zero;
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationPulse = Duration(milliseconds: 1200);

  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curvePulse = Curves.easeInOutBack;

  /// Helper method that checks context for reduced motion setting
  /// and returns Duration.zero if reduced motion is enabled.
  static Duration getEffectiveDuration(BuildContext context, Duration duration) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery != null && mediaQuery.disableAnimations) {
      return Duration.zero;
    }
    return duration;
  }
}
