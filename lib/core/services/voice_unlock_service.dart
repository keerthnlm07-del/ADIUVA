import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'local_storage_service.dart';
import 'stt_service.dart';
import 'tts_service.dart';

/// Secure Voice / Quick Unlock Service for ADIUVA Authenticated Sessions
class VoiceUnlockService {
  final LocalStorageService _localStorageService;
  final SttService _sttService;
  final TtsService _ttsService;

  static const String _pinHashKey = 'voice_unlock_pin_hash';
  static const String _isEnabledKey = 'voice_unlock_enabled';

  int _failedAttempts = 0;
  static const int maxFailedAttempts = 3;

  VoiceUnlockService({
    required LocalStorageService localStorageService,
    required SttService sttService,
    required TtsService ttsService,
  })  : _localStorageService = localStorageService,
        _sttService = sttService,
        _ttsService = ttsService;

  int get failedAttempts => _failedAttempts;
  bool get isLockedOut => _failedAttempts >= maxFailedAttempts;

  /// Check if Voice Unlock is setup and enabled
  Future<bool> isVoiceUnlockEnabled() async {
    final enabled = (await _localStorageService.getBool(_isEnabledKey)) ?? false;
    final hash = await _localStorageService.getString(_pinHashKey);
    return enabled && hash != null && hash.isNotEmpty;
  }

  /// Save a 6-digit PIN securely as a SHA-256 hash
  Future<bool> setupPin(String sixDigitPin) async {
    final cleanPin = sixDigitPin.replaceAll(RegExp(r'\D'), '');
    if (cleanPin.length != 6) {
      await _ttsService.speak('PIN must be exactly 6 digits.');
      return false;
    }

    final bytes = utf8.encode(cleanPin);
    final digest = sha256.convert(bytes).toString();

    await _localStorageService.saveString(_pinHashKey, digest);
    await _localStorageService.saveBool(_isEnabledKey, true);
    _failedAttempts = 0;

    await _ttsService.speak('Voice unlock PIN has been saved securely.');
    return true;
  }

  /// Spoken word to digit normalizer
  String normalizeSpokenDigits(String input) {
    String text = input.toLowerCase();

    final Map<String, String> wordToDigit = {
      'zero': '0', 'oh': '0',
      'one': '1', 'won': '1',
      'two': '2', 'to': '2', 'too': '2',
      'three': '3', 'tree': '3',
      'four': '4', 'for': '4', 'fore': '4',
      'five': '5',
      'six': '6', 'sex': '6',
      'seven': '7',
      'eight': '8', 'ate': '8',
      'nine': '9',
    };

    wordToDigit.forEach((word, digit) {
      text = text.replaceAll(RegExp('\\b$word\\b'), digit);
    });

    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
    return digitsOnly;
  }

  /// Start speech recognition for Voice Unlock
  Future<void> listenAndUnlock({
    required Function(String spokenDigits, bool isSuccess) onResult,
  }) async {
    if (isLockedOut) {
      await _ttsService.speak('Maximum failed attempts reached. Please use normal login.');
      onResult('', false);
      return;
    }

    await _ttsService.speak('Please speak your six digit PIN now.');
    await Future.delayed(const Duration(milliseconds: 1500));

    await _sttService.startListening(
      onResult: (transcript) async {
        final digits = normalizeSpokenDigits(transcript);
        if (digits.length == 6) {
          final isSuccess = await verifyPin(digits);
          onResult(digits, isSuccess);
        }
      },
      onComplete: () {},
    );
  }

  /// Verify entered/spoken PIN against stored SHA-256 hash
  Future<bool> verifyPin(String sixDigitPin) async {
    if (isLockedOut) return false;

    final storedHash = await _localStorageService.getString(_pinHashKey);
    if (storedHash == null) return false;

    final bytes = utf8.encode(sixDigitPin);
    final inputHash = sha256.convert(bytes).toString();

    if (inputHash == storedHash) {
      _failedAttempts = 0;
      await _ttsService.speak('Voice unlock successful. Welcome back to Adiuva.');
      return true;
    } else {
      _failedAttempts++;
      final remaining = maxFailedAttempts - _failedAttempts;
      if (remaining > 0) {
        await _ttsService.speak('Incorrect PIN. You have $remaining attempts remaining.');
      } else {
        await _ttsService.speak('Incorrect PIN. Maximum attempts reached. Please use account login.');
      }
      return false;
    }
  }

  /// Reset failed attempts on full authentication
  void resetLockout() {
    _failedAttempts = 0;
  }

  /// Disable Voice Unlock
  Future<void> disableVoiceUnlock() async {
    await _localStorageService.saveBool(_isEnabledKey, false);
    await _localStorageService.remove(_pinHashKey);
    _failedAttempts = 0;
  }
}
