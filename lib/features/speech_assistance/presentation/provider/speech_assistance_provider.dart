import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../../../core/services/tts_service.dart';
import '../../domain/entities/chat_message.dart';

/// Provider managing AI Assistant conversation state and Firebase Gemini AI calls
class SpeechAssistanceProvider extends ChangeNotifier {
  final TtsService _ttsService;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  GenerativeModel? _generativeModel;

  SpeechAssistanceProvider({required TtsService ttsService})
      : _ttsService = ttsService {
    _initGeminiModel();
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSpeaking => _ttsService.isSpeaking;

  void _initGeminiModel() {
    if (_generativeModel != null) return;
    try {
      final stopwatch = Stopwatch()..start();
      _generativeModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
      );
      stopwatch.stop();
      debugPrint('[GEMINI] Model (gemini-3.8-flash) initialized in ${stopwatch.elapsedMilliseconds} ms');
    } catch (e, stackTrace) {
      debugPrint('[GEMINI] Model init error: $e');
      debugPrint('[GEMINI] StackTrace: $stackTrace');
      _errorMessage = 'Failed to initialize Gemini AI.';
    }
  }

  /// Send prompt to Gemini AI
  Future<void> sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _isLoading) return;

    _errorMessage = null;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: prompt,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);

    final assistantMsgId = '${DateTime.now().millisecondsSinceEpoch}_ai';
    final pendingAssistantMsg = ChatMessage(
      id: assistantMsgId,
      text: 'Gemini is thinking...',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    _messages.add(pendingAssistantMsg);
    _isLoading = true;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    final logPrompt = prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt;
    debugPrint('[GEMINI] REQUEST START for: "$logPrompt"');

    try {
      _initGeminiModel();

      if (_generativeModel == null) {
        throw Exception('Gemini AI model is unavailable.');
      }

      debugPrint('[GEMINI] SENDING REQUEST to gemini-3.8-flash...');
      final response = await _generativeModel!
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 45));

      stopwatch.stop();
      debugPrint('[GEMINI] RESPONSE RECEIVED in ${stopwatch.elapsedMilliseconds} ms');

      final responseText = response.text?.trim() ?? 'No response received from Gemini.';

      final index = _messages.indexWhere((m) => m.id == assistantMsgId);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: assistantMsgId,
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: false,
        );
      }
    } on TimeoutException catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('[GEMINI] REQUEST TIMEOUT after ${stopwatch.elapsedMilliseconds} ms: $e');
      debugPrint('[GEMINI] StackTrace: $stackTrace');
      _handleError(assistantMsgId, "I couldn't process your request right now. Please try again.");
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('[GEMINI] REQUEST ERROR after ${stopwatch.elapsedMilliseconds} ms: $e');
      debugPrint('[GEMINI] StackTrace: $stackTrace');
      _handleError(assistantMsgId, "I couldn't process your request right now. Please try again.");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retry the last user prompt
  Future<void> retryLastPrompt() async {
    final lastUserMsgIndex = _messages.lastIndexWhere((m) => m.isUser);
    if (lastUserMsgIndex != -1) {
      final lastPrompt = _messages[lastUserMsgIndex].text;
      await sendMessage(lastPrompt);
    }
  }

  void _handleError(String assistantMsgId, String errText) {
    _errorMessage = errText;
    final index = _messages.indexWhere((m) => m.id == assistantMsgId);

    if (index != -1) {
      _messages[index] = ChatMessage(
        id: assistantMsgId,
        text: errText,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
        isStreaming: false,
      );
    }
  }

  /// Speak Assistant Response via TTS
  Future<void> speakResponse(String text) async {
    if (text.isEmpty) return;
    await _ttsService.speak(text);
  }

  /// Alias for speakResponse
  Future<void> speakMessage(String text) async {
    await speakResponse(text);
  }

  /// Stop current TTS Speech
  Future<void> stopSpeech() async {
    await _ttsService.stop();
    notifyListeners();
  }

  /// Clear Conversation History
  void clearHistory() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
