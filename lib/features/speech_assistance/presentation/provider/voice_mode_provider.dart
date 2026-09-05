import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../../../core/services/stt_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../config/routes/app_routes.dart';

/// Explicit States for Voice Mode Operation
enum VoiceStateEnum {
  idle,
  listening,
  processing,
  speaking,
  paused,
  error,
}

/// Provider managing Voice Mode state machine, local intent handling, STT, Gemini 3.8 Flash, and TTS
class VoiceModeProvider extends ChangeNotifier {
  final SttService _sttService;
  final TtsService _ttsService;

  VoiceStateEnum _state = VoiceStateEnum.idle;
  String _liveTranscript = '';
  String _assistantResponse = '';
  String? _errorMessage;
  String? _pendingNavigationRoute;
  GenerativeModel? _generativeModel;
  bool _isProcessingInput = false;

  VoiceModeProvider({
    required SttService sttService,
    required TtsService ttsService,
  })  : _sttService = sttService,
        _ttsService = ttsService {
    _initGeminiModel();
    _ttsService.setCompletionListener(_onTtsComplete);
  }

  VoiceStateEnum get state => _state;
  String get liveTranscript => _liveTranscript;
  String get assistantResponse => _assistantResponse;
  String? get errorMessage => _errorMessage;
  String? get pendingNavigationRoute => _pendingNavigationRoute;
  bool get isSpeaking => _ttsService.isSpeaking;

  void clearNavigationRoute() {
    _pendingNavigationRoute = null;
  }

  void _initGeminiModel() {
    if (_generativeModel != null) return;
    try {
      final stopwatch = Stopwatch()..start();
      _generativeModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
      );
      stopwatch.stop();
      debugPrint('[VOICE GEMINI] Model (gemini-3.8-flash) initialized in ${stopwatch.elapsedMilliseconds} ms');
    } catch (e, stackTrace) {
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] Init exception: $e');
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] StackTrace: $stackTrace');
      _errorMessage = 'Failed to initialize Gemini AI.';
    }
  }

  void _onTtsComplete() {
    debugPrint('[VOICE MODE] TTS playback complete. Resetting to idle state.');
    if (_state == VoiceStateEnum.speaking) {
      _state = VoiceStateEnum.idle;
      _isProcessingInput = false;
      notifyListeners();
    }
  }

  /// Start or toggle voice interaction session (Barge-in aware)
  Future<void> toggleVoiceSession() async {
    // Barge-in check: If currently speaking or TTS active, stop speech immediately
    if (_state == VoiceStateEnum.speaking || _ttsService.isSpeaking) {
      await stopSession();
      return;
    }

    if (_state == VoiceStateEnum.listening) {
      await _sttService.stopListening();
      _state = VoiceStateEnum.idle;
      notifyListeners();
      return;
    }

    await startListening();
  }

  /// Start active STT listening
  Future<void> startListening() async {
    await stopSession(); // Clean reset of previous session

    _isProcessingInput = false;
    _state = VoiceStateEnum.listening;
    _liveTranscript = 'Listening... Speak now.';
    _assistantResponse = '';
    _errorMessage = null;
    _pendingNavigationRoute = null;
    notifyListeners();

    await _sttService.startListening(
      onResult: (text) {
        if (_isProcessingInput) return; // Guard against duplicate submissions

        final cleanText = text.trim();
        if (cleanText.isNotEmpty && cleanText != 'Listening... Speak now.') {
          _liveTranscript = cleanText;
          notifyListeners();

          // Check if the recognized text is a known fast local command -> process immediately
          if (_isLocalCommand(cleanText)) {
            debugPrint('[VOICE MODE] Fast local intent detected in onResult: "$cleanText". Stopping mic immediately.');
            _sttService.stopListening();
            _handleSpokenInput(cleanText);
          }
        }
      },
      onComplete: () {
        if (_isProcessingInput) return; // Guard against duplicate submissions

        final cleanWords = _liveTranscript.trim();
        if (cleanWords.isNotEmpty && cleanWords != 'Listening... Speak now.') {
          _handleSpokenInput(cleanWords);
        } else {
          _state = VoiceStateEnum.error;
          _errorMessage = "Sorry, I couldn't hear that. Please try again.";
          _isProcessingInput = false;
          notifyListeners();
        }
      },
    );
  }

  /// Check if transcript matches a known local command
  bool _isLocalCommand(String transcript) {
    final lower = transcript.toLowerCase().trim();
    return lower == 'hello' ||
        lower == 'hi' ||
        lower == 'hey' ||
        lower.startsWith('hello ') ||
        lower.startsWith('hi ') ||
        lower == 'help' ||
        lower.contains('what can you do') ||
        lower == 'stop' ||
        lower == 'cancel' ||
        lower == 'quiet' ||
        lower == 'hush' ||
        lower.contains('describe scene') ||
        lower.contains('open vision') ||
        lower.contains('read text') ||
        lower.contains('identify object') ||
        lower.contains('scan code') ||
        lower.contains('emergency') ||
        lower.contains('settings') ||
        lower.contains('profile');
  }

  /// Process spoken text cleanly with microphone separation & duplicate protection
  Future<void> _handleSpokenInput(String transcript) async {
    if (_isProcessingInput) {
      debugPrint('[VOICE MODE] Duplicate submission prevented for: "$transcript"');
      return;
    }

    _isProcessingInput = true;
    
    // STEP 1: CLEANLY RELEASE MICROPHONE BEFORE PROCESSING
    await _sttService.stopListening();

    _state = VoiceStateEnum.processing;
    notifyListeners();

    final lower = transcript.toLowerCase().trim();
    debugPrint('[VOICE MODE] Dispatching command: "$transcript"');

    // 1. FAST LOCAL GREETING (NEVER CALLS GEMINI / NETWORK)
    if (lower == 'hello' || lower == 'hi' || lower == 'hey' || lower.startsWith('hello ') || lower.startsWith('hi ')) {
      debugPrint('[VOICE MODE] [LOCAL INTENT] Greeting handled locally. Zero network / Gemini calls.');
      await _respondLocally("Hello! How can I help you?");
      return;
    }

    // 2. FAST LOCAL HELP
    if (lower == 'help' || lower.contains('what can you do') || lower == 'help me') {
      debugPrint('[VOICE MODE] [LOCAL INTENT] Help handled locally.');
      await _respondLocally(
        "I can describe scenes, read text out loud, identify objects, scan codes, or answer your questions with AI. What would you like to do?"
      );
      return;
    }

    // 3. FAST LOCAL STOP
    if (lower == 'stop' || lower == 'cancel' || lower == 'quiet' || lower == 'hush') {
      debugPrint('[VOICE MODE] [LOCAL INTENT] Stop command handled locally.');
      await stopSession();
      return;
    }

    // 4. FAST LOCAL NAVIGATION COMMANDS
    if (lower.contains('describe scene') || lower.contains('open vision') || lower == 'vision') {
      debugPrint('[VOICE MODE] [LOCAL NAVIGATION] Opening Vision Scene Description.');
      _pendingNavigationRoute = AppRoutes.vision;
      await _respondLocally("Opening Scene Description.");
      return;
    }

    if (lower.contains('read text') || lower.contains('read text out loud') || lower == 'ocr') {
      debugPrint('[VOICE MODE] [LOCAL NAVIGATION] Opening Text Reader.');
      _pendingNavigationRoute = AppRoutes.vision;
      await _respondLocally("Opening Text Reader.");
      return;
    }

    if (lower.contains('identify object') || lower.contains('object detection')) {
      debugPrint('[VOICE MODE] [LOCAL NAVIGATION] Opening Object Detection.');
      _pendingNavigationRoute = AppRoutes.vision;
      await _respondLocally("Opening Object Detection.");
      return;
    }

    if (lower.contains('scan code') || lower.contains('scan qr') || lower.contains('qr code') || lower == 'barcode') {
      debugPrint('[VOICE MODE] [LOCAL NAVIGATION] Opening Code Scanner.');
      _pendingNavigationRoute = AppRoutes.vision;
      await _respondLocally("Opening Code Scanner.");
      return;
    }

    if (lower.contains('emergency') || lower.contains('open sos')) {
      debugPrint('[VOICE MODE] [LOCAL NAVIGATION] Opening Emergency SOS.');
      _pendingNavigationRoute = AppRoutes.emergencySos;
      await _respondLocally("Opening Emergency SOS.");
      return;
    }

    if (lower.contains('settings') || lower.contains('open settings')) {
      debugPrint('[VOICE MODE] [LOCAL NAVIGATION] Opening Settings.');
      _pendingNavigationRoute = AppRoutes.accessibilitySettings;
      await _respondLocally("Opening Accessibility Settings.");
      return;
    }

    if (lower.contains('profile') || lower.contains('open profile')) {
      debugPrint('[VOICE MODE] [LOCAL NAVIGATION] Opening Profile.');
      _pendingNavigationRoute = AppRoutes.home;
      await _respondLocally("Opening Profile.");
      return;
    }

    // 5. GEMINI 3.8 FLASH FOR AI CONVERSATIONAL COMMANDS
    await _processTranscriptWithGemini(transcript);
  }

  /// Respond locally with zero latency for predefined voice commands
  Future<void> _respondLocally(String responseText) async {
    _assistantResponse = responseText;
    _state = VoiceStateEnum.speaking;
    notifyListeners();

    await _ttsService.speak(_assistantResponse);
  }

  /// Process general speech transcript through Firebase AI Gemini 3.8 Flash model
  Future<void> _processTranscriptWithGemini(String prompt) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[VOICE GEMINI] REQUEST START for: "$prompt"');

    try {
      _initGeminiModel();

      if (_generativeModel == null) {
        throw Exception('Gemini AI model is unavailable.');
      }

      final promptWithConstraint = 
          '$prompt\n\n(Respond in 1 to 3 short, clear sentences suitable for spoken text-to-speech for a blind user. Be concise, direct, and accessible.)';

      debugPrint('[VOICE GEMINI] SENDING REQUEST to gemini-3.8-flash...');
      final response = await _generativeModel!
          .generateContent([Content.text(promptWithConstraint)])
          .timeout(const Duration(seconds: 45));

      stopwatch.stop();
      debugPrint('[VOICE GEMINI] RESPONSE RECEIVED in ${stopwatch.elapsedMilliseconds} ms');

      _assistantResponse = response.text?.trim() ?? 'No response received from Gemini.';
      _state = VoiceStateEnum.speaking;
      notifyListeners();

      await _ttsService.speak(_assistantResponse);
    } on TimeoutException catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] REQUEST TIMEOUT after ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] Exception type: TimeoutException');
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] Exception details: $e');
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] StackTrace: $stackTrace');
      
      _state = VoiceStateEnum.error;
      _errorMessage = "I couldn't connect to the AI service. Please try again.";
      notifyListeners();
      await _ttsService.speak(_errorMessage!);
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] REQUEST EXCEPTION after ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] Exception type: ${e.runtimeType}');
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] Exception details: $e');
      debugPrint('[VOICE GEMINI] [ERROR DIAGNOSTIC] StackTrace: $stackTrace');

      _state = VoiceStateEnum.error;
      _errorMessage = "I couldn't connect to the AI service. Please try again.";
      notifyListeners();
      await _ttsService.speak(_errorMessage!);
    } finally {
      if (_state != VoiceStateEnum.speaking && !_ttsService.isSpeaking) {
        _state = VoiceStateEnum.idle;
        _isProcessingInput = false;
        notifyListeners();
      }
    }
  }

  /// Stop current voice session & speech
  Future<void> stopSession() async {
    await _sttService.stopListening();
    await _ttsService.stop();
    _isProcessingInput = false;
    _state = VoiceStateEnum.idle;
    notifyListeners();
  }

  /// Reset voice session state
  Future<void> reset() async {
    await stopSession();
  }
}
