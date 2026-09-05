import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// ADIUVA Text-to-Speech (TTS) Service Wrapper
class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  VoidCallback? _onCompletionCallback;

  bool get isSpeaking => _isSpeaking;

  TtsService() {
    _initTts();
  }

  void setCompletionListener(VoidCallback onComplete) {
    _onCompletionCallback = onComplete;
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
        _isSpeaking = false;
        notifyListeners();
        _onCompletionCallback?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        notifyListeners();
        _onCompletionCallback?.call();
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

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }
}
