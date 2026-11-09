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
  VoidCallback? _activeOnComplete;
  bool _hasEmittedFinal = false;
  int _currentSessionId = 0;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String? get errorMessage => _errorMessage;

  void _dispatchOnComplete(int sessionId) {
    if (sessionId != _currentSessionId) {
      debugPrint('[STT SERVICE] Ignoring stale onComplete for session $sessionId (current: $_currentSessionId)');
      return;
    }
    if (!_hasEmittedFinal && _activeOnComplete != null) {
      _hasEmittedFinal = true;
      final callback = _activeOnComplete;
      _activeOnComplete = null;
      callback?.call();
    }
  }

  /// Check microphone permission and initialize SpeechToText instance
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('[VOICE_DEVICE] STT initialize already completed: true');
      return true;
    }

    debugPrint('[VOICE_DEVICE] STT initialize started');
    try {
      final status = await Permission.microphone.request();
      debugPrint('[VOICE_DEVICE] permission = ${status.isGranted ? "granted" : "denied"}');
      if (!status.isGranted) {
        _errorMessage = 'Microphone permission is required for speech recognition.';
        notifyListeners();
        debugPrint('[VOICE_DEVICE] STT initialize result = false (permission denied)');
        return false;
      }

      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('[STT SERVICE] Status change: $status');
          debugPrint('[VOICE_DEVICE] onStatus = $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
            _dispatchOnComplete(_currentSessionId);
          }
        },
        onError: (errorNotification) {
          debugPrint('[STT SERVICE] Error: ${errorNotification.errorMsg}');
          debugPrint('[VOICE_DEVICE] onError = ${errorNotification.errorMsg}');
          _isListening = false;
          _errorMessage = errorNotification.errorMsg;
          notifyListeners();
          _dispatchOnComplete(_currentSessionId);
        },
      );

      debugPrint('[VOICE_DEVICE] STT initialize result = $_isInitialized');
      debugPrint('[VOICE_DEVICE] available = $_isInitialized');
      notifyListeners();
      return _isInitialized;
    } catch (e) {
      debugPrint('[VOICE_DEVICE] STT initialize exception = $e');
      _errorMessage = 'Failed to initialize speech recognition: $e';
      notifyListeners();
      return false;
    }
  }

  /// Start active listening for speech input (optimized pauseFor: 2.0s and search mode)
  Future<void> startListening({
    required Function onResult,
    required VoidCallback onComplete,
    String? localeId,
  }) async {
    // Ensure any existing STT session is stopped cleanly before starting a new one
    if (_isListening || _speechToText.isListening) {
      _activeOnComplete = null;
      _currentSessionId++;
      try {
        await _speechToText.stop();
      } catch (_) {}
      _isListening = false;
      await Future.delayed(const Duration(milliseconds: 250));
    }

    final int sessionId = ++_currentSessionId;
    _lastWords = '';
    _errorMessage = null;
    _activeOnComplete = onComplete;
    _hasEmittedFinal = false;

    debugPrint('[VOICE_DEVICE] locale = ${localeId ?? "en-IN"} (session $sessionId)');
    debugPrint('[VOICE_DEVICE] startListening called');

    final available = await initialize();
    if (!available) {
      _dispatchOnComplete(sessionId);
      return;
    }

    _isListening = true;
    notifyListeners();

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (sessionId != _currentSessionId) {
            debugPrint('[STT SERVICE] Ignoring stale onResult for session $sessionId');
            return;
          }
          final words = result.recognizedWords.trim();
          final isFinal = result.finalResult;
          debugPrint('[VOICE_STT] status=${isFinal ? "final" : "interim"} text="$words"');
          debugPrint('[VOICE_DEVICE] onResult = $words');

          if (words.isNotEmpty && words != 'Listening... Speak now.') {
            _lastWords = words;
            try {
              (onResult as dynamic)(_lastWords, isFinal);
            } catch (_) {
              (onResult as dynamic)(_lastWords);
            }
            notifyListeners();
          }

          if (isFinal) {
            _isListening = false;
            notifyListeners();
            _dispatchOnComplete(sessionId);
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          cancelOnError: true,
          listenMode: ListenMode.search,
          pauseFor: const Duration(milliseconds: 2000),
        ),
      );
    } catch (e) {
      debugPrint('[VOICE_DEVICE] onError = $e');
      _isListening = false;
      _errorMessage = 'Speech listening error: $e';
      notifyListeners();
      _dispatchOnComplete(sessionId);
    }
  }

  /// Stop listening cleanly and release microphone
  Future<void> stopListening() async {
    _activeOnComplete = null;
    _currentSessionId++; // Invalidate active session callbacks
    if (_isListening || _speechToText.isListening) {
      try {
        await _speechToText.stop();
      } catch (_) {}
      _isListening = false;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  /// Cancel listening and discard audio buffer
  Future<void> cancelListening() async {
    _activeOnComplete = null;
    _currentSessionId++;
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
