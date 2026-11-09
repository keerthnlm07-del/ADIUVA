import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// ADIUVA Text-to-Speech (TTS) Service Wrapper
class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  final List<VoidCallback> _completionListeners = [];

  bool get isSpeaking => _isSpeaking;

  TtsService() {
    _initTts();
  }

  void setCompletionListener(VoidCallback onComplete) {
    if (!_completionListeners.contains(onComplete)) {
      _completionListeners.add(onComplete);
    }
  }

  void addCompletionListener(VoidCallback onComplete) {
    if (!_completionListeners.contains(onComplete)) {
      _completionListeners.add(onComplete);
    }
  }

  void removeCompletionListener(VoidCallback onComplete) {
    _completionListeners.remove(onComplete);
  }

  void _notifyCompletionListeners() {
    _isSpeaking = false;
    notifyListeners();
    for (final listener in List<VoidCallback>.from(_completionListeners)) {
      try {
        listener();
      } catch (e) {
        debugPrint('[TTS] Error invoking completion listener: $e');
      }
    }
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _notifyCompletionListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        _notifyCompletionListeners();
      });
    } catch (_) {
      // Graceful fallback if TTS engine is unavailable
    }
  }

  Future<void> speak(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    try {
      await stop();
      _isSpeaking = true;
      notifyListeners();
      await _flutterTts.speak(cleanText);
    } catch (_) {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
    } catch (_) {}
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (_) {}
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }
}
