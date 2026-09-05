import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// ADIUVA Speech-To-Text (STT) Service Wrapper
class SttService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String? get errorMessage => _errorMessage;

  /// Check microphone permission and initialize SpeechToText instance
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _errorMessage = 'Microphone permission is required for speech recognition.';
        notifyListeners();
        return false;
      }

      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('[STT SERVICE] Status change: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (errorNotification) {
          debugPrint('[STT SERVICE] Error: ${errorNotification.errorMsg}');
          _isListening = false;
          _errorMessage = errorNotification.errorMsg;
          notifyListeners();
        },
      );

      notifyListeners();
      return _isInitialized;
    } catch (e) {
      _errorMessage = 'Failed to initialize speech recognition: $e';
      notifyListeners();
      return false;
    }
  }

  /// Start active listening for speech input (optimized pauseFor: 1.5s and search mode)
  Future<void> startListening({
    required ValueChanged<String> onResult,
    required VoidCallback onComplete,
  }) async {
    _lastWords = '';
    _errorMessage = null;

    final available = await initialize();
    if (!available) {
      onComplete();
      return;
    }

    _isListening = true;
    notifyListeners();

    bool hasEmittedFinal = false;

    try {
      await _speechToText.listen(
        onResult: (result) {
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty && words != 'Listening... Speak now.') {
            _lastWords = words;
            onResult(_lastWords);
            notifyListeners();
          }

          if (result.finalResult && !hasEmittedFinal) {
            hasEmittedFinal = true;
            _isListening = false;
            notifyListeners();
            onComplete();
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          listenMode: ListenMode.search,
          pauseFor: const Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      _isListening = false;
      _errorMessage = 'Speech listening error: $e';
      notifyListeners();
      onComplete();
    }
  }

  /// Stop listening cleanly and release microphone
  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speechToText.stop();
      } catch (_) {}
      _isListening = false;
      notifyListeners();
    }
  }

  /// Cancel listening and discard audio buffer
  Future<void> cancelListening() async {
    if (_isListening) {
      try {
        await _speechToText.cancel();
      } catch (_) {}
      _isListening = false;
      _lastWords = '';
      notifyListeners();
    }
  }
}
