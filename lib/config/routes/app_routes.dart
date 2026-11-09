import 'package:flutter/material.dart';

/// Centralized Route Name Constants for ADIUVA Application
class AppRoutes {
  AppRoutes._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String aiAssistant = '/ai-assistant';
  static const String vision = '/vision';
  static const String voiceMode = '/voice-mode';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String accessibilitySettings = '/settings/accessibility';
  static const String voiceSettings = '/settings/voice';
  static const String languageSettings = '/settings/language';
  static const String appearanceSettings = '/settings/appearance';
  static const String notifications = '/notifications';
  static const String privacySettings = '/settings/privacy';
  static const String emergencySos = '/emergency-sos';
  static const String emergencyContacts = '/emergency-contacts';
  static const String addEmergencyContact = '/add-emergency-contact';

  // Feature dashboard routes
  static const String blindMode = '/blind-mode';
  static const String hearingAssistance = '/hearing-assistance';
  static const String cognitiveAssistance = '/cognitive-assistance';
  static const String physicalAssistance = '/physical-assistance';
  static const String normalUser = '/normal-user';
  static const String assistanceSetup = '/assistance-setup';
  static const String todoList = '/todo-list';
  static const String reminders = '/reminders';
  static const String notes = '/notes';
  static const String translator = '/translator';
  static const String signLanguage = '/sign-language';
  static const String signToText = '/sign-to-text';
  static const String textToSign = '/text-to-sign';
  static const String location = '/location';
}
