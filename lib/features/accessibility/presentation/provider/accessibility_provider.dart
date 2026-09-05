import 'package:flutter/material.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/tts_service.dart';

/// Provider managing application Accessibility, Speech, Language, Theme, and Privacy Settings
class AccessibilityProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final TtsService _ttsService;

  // Accessibility Settings
  bool _isHighContrast = false;
  bool _isScreenReaderOptimized = true;
  bool _screenReaderHints = true;
  bool _isBoldText = false;
  double _fontScale = 1.0; // 1.0 (100%), 1.25 (125%), 1.5 (150%), 2.0 (200%)
  bool _disableAnimations = false;
  bool _enableHaptics = true;
  bool _enableVoiceFeedback = true;

  // Voice & Speech Settings
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  double _speechVolume = 1.0;

  // Language & Locale Settings
  String _appLanguage = 'en';
  String _speechLocale = 'en-US';

  // Theme Settings
  ThemeMode _themeMode = ThemeMode.system;

  // Notifications Settings
  bool _pushNotificationsEnabled = true;
  bool _emergencyAlertsEnabled = true;

  AccessibilityProvider({
    required LocalStorageService localStorageService,
    required TtsService ttsService,
  })  : _localStorageService = localStorageService,
        _ttsService = ttsService {
    loadSettings();
  }

  // Getters
  bool get isHighContrast => _isHighContrast;
  bool get isScreenReaderOptimized => _isScreenReaderOptimized;
  bool get screenReaderHints => _screenReaderHints;
  bool get isBoldText => _isBoldText;
  double get fontScale => _fontScale;
  bool get disableAnimations => _disableAnimations;
  bool get enableHaptics => _enableHaptics;
  bool get enableVoiceFeedback => _enableVoiceFeedback;
  double get speechRate => _speechRate;
  double get speechPitch => _speechPitch;
  double get speechVolume => _speechVolume;
  String get appLanguage => _appLanguage;
  String get speechLocale => _speechLocale;
  ThemeMode get themeMode => _themeMode;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get emergencyAlertsEnabled => _emergencyAlertsEnabled;

  /// Load persisted settings from LocalStorageService
  Future<void> loadSettings() async {
    try {
      _isHighContrast = (await _localStorageService.getBool('high_contrast')) ?? false;
      _isScreenReaderOptimized = (await _localStorageService.getBool('screen_reader_opt')) ?? true;
      _screenReaderHints = (await _localStorageService.getBool('screen_reader_hints')) ?? true;
      _isBoldText = (await _localStorageService.getBool('bold_text')) ?? false;
      _fontScale = (await _localStorageService.getDouble('font_scale')) ?? 1.0;
      _disableAnimations = (await _localStorageService.getBool('disable_animations')) ?? false;
      _enableHaptics = (await _localStorageService.getBool('enable_haptics')) ?? true;
      _enableVoiceFeedback = (await _localStorageService.getBool('voice_feedback')) ?? true;

      _speechRate = (await _localStorageService.getDouble('speech_rate')) ?? 0.5;
      _speechPitch = (await _localStorageService.getDouble('speech_pitch')) ?? 1.0;
      _speechVolume = (await _localStorageService.getDouble('speech_volume')) ?? 1.0;

      _appLanguage = (await _localStorageService.getString('app_language')) ?? 'en';
      _speechLocale = (await _localStorageService.getString('speech_locale')) ?? 'en-US';
      
      final themeStr = await _localStorageService.getString('theme_mode');
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }

      _pushNotificationsEnabled = (await _localStorageService.getBool('push_notifications')) ?? true;
      _emergencyAlertsEnabled = (await _localStorageService.getBool('emergency_alerts')) ?? true;

      notifyListeners();
    } catch (_) {}
  }

  // Setters with LocalStorage persistence

  Future<void> setHighContrast(bool value) async {
    _isHighContrast = value;
    await _localStorageService.saveBool('high_contrast', value);
    notifyListeners();
  }

  Future<void> setScreenReaderOptimized(bool value) async {
    _isScreenReaderOptimized = value;
    await _localStorageService.saveBool('screen_reader_opt', value);
    notifyListeners();
  }

  Future<void> setScreenReaderHints(bool value) async {
    _screenReaderHints = value;
    await _localStorageService.saveBool('screen_reader_hints', value);
    notifyListeners();
  }

  Future<void> setBoldText(bool value) async {
    _isBoldText = value;
    await _localStorageService.saveBool('bold_text', value);
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value;
    await _localStorageService.saveDouble('font_scale', value);
    notifyListeners();
  }

  Future<void> setDisableAnimations(bool value) async {
    _disableAnimations = value;
    await _localStorageService.saveBool('disable_animations', value);
    notifyListeners();
  }

  Future<void> setEnableHaptics(bool value) async {
    _enableHaptics = value;
    await _localStorageService.saveBool('enable_haptics', value);
    notifyListeners();
  }

  Future<void> setEnableVoiceFeedback(bool value) async {
    _enableVoiceFeedback = value;
    await _localStorageService.saveBool('voice_feedback', value);
    notifyListeners();
  }

  Future<void> setSpeechRate(double value) async {
    _speechRate = value;
    await _localStorageService.saveDouble('speech_rate', value);
    notifyListeners();
  }

  Future<void> setSpeechPitch(double value) async {
    _speechPitch = value;
    await _localStorageService.saveDouble('speech_pitch', value);
    notifyListeners();
  }

  Future<void> setSpeechVolume(double value) async {
    _speechVolume = value;
    await _localStorageService.saveDouble('speech_volume', value);
    notifyListeners();
  }

  Future<void> setAppLanguage(String languageCode) async {
    _appLanguage = languageCode;
    await _localStorageService.saveString('app_language', languageCode);
    notifyListeners();
  }

  Future<void> setSpeechLocale(String locale) async {
    _speechLocale = locale;
    await _localStorageService.saveString('speech_locale', locale);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await _localStorageService.saveString('theme_mode', modeStr);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    _pushNotificationsEnabled = value;
    await _localStorageService.saveBool('push_notifications', value);
    notifyListeners();
  }

  Future<void> setEmergencyAlerts(bool value) async {
    _emergencyAlertsEnabled = value;
    await _localStorageService.saveBool('emergency_alerts', value);
    notifyListeners();
  }

  /// Speak sample speech preview using TtsService
  Future<void> testSpeech() async {
    await _ttsService.speak('This is a preview of ADIUVA speech synthesis.');
  }

  /// Clear all app settings & local storage cache
  Future<void> clearAllSettings() async {
    await _localStorageService.clearAll();
    await loadSettings();
  }
}
