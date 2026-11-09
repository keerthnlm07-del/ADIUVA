import 'package:flutter/material.dart';
import '../../config/routes/app_routes.dart';

/// Centralized Application-Level Navigation Service for ADIUVA
/// Ensures all global voice navigation uses AppRoutes.navigatorKey.currentState safely.
class NavigationService {
  NavigationService._();

  static GlobalKey<NavigatorState> get navigatorKey => AppRoutes.navigatorKey;

  static NavigatorState? get _navState => AppRoutes.navigatorKey.currentState;

  static void goHome() {
    debugPrint('[NAV_SERVICE] goHome -> pushNamedAndRemoveUntil(AppRoutes.home)');
    _navState?.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  static void openLocation() {
    debugPrint('[NAV_SERVICE] openLocation -> AppRoutes.location');
    _navState?.pushNamed(AppRoutes.location);
  }

  static void openHearing() {
    debugPrint('[NAV_SERVICE] openHearing -> AppRoutes.hearingAssistance');
    _navState?.pushNamed(AppRoutes.hearingAssistance);
  }

  static void openCognitive() {
    debugPrint('[NAV_SERVICE] openCognitive -> AppRoutes.cognitiveAssistance');
    _navState?.pushNamed(AppRoutes.cognitiveAssistance);
  }

  static void openPhysical() {
    debugPrint('[NAV_SERVICE] openPhysical -> AppRoutes.physicalAssistance');
    _navState?.pushNamed(AppRoutes.physicalAssistance);
  }

  static void openVisual() {
    debugPrint('[NAV_SERVICE] openVisual -> AppRoutes.blindMode');
    _navState?.pushNamed(AppRoutes.blindMode);
  }

  static void openNormalUser() {
    debugPrint('[NAV_SERVICE] openNormalUser -> AppRoutes.normalUser');
    _navState?.pushNamed(AppRoutes.normalUser);
  }

  static void openTranslator() {
    debugPrint('[NAV_SERVICE] openTranslator -> AppRoutes.translator');
    _navState?.pushNamed(AppRoutes.translator);
  }

  static void openEmergencySos() {
    debugPrint('[NAV_SERVICE] openEmergencySos -> AppRoutes.emergencySos');
    _navState?.pushNamed(AppRoutes.emergencySos);
  }

  static void goBack() {
    debugPrint('[NAV_SERVICE] goBack');
    if (_navState != null && _navState!.canPop()) {
      _navState!.pop();
    }
  }
}
