import 'package:flutter/foundation.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import '../registries/sign_language_phrase_registry.dart';
import '../../domain/entities/sign_language_phrase.dart';

/// Animation controller service for switching 3D ISL avatar animations
class SignLanguageAnimationService {
  Flutter3DController? _controller;
  SignLanguagePhrase? _activePhrase;
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _statusMessage;

  SignLanguagePhrase? get activePhrase => _activePhrase;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  String? get statusMessage => _statusMessage;

  void attachController(Flutter3DController controller) {
    _controller = controller;
    debugPrint('[SIGN_TRACE] 3D Controller attached');
  }

  void detachController() {
    _controller = null;
    debugPrint('[SIGN_TRACE] 3D Controller detached');
  }

  /// Play ISL sign animation by matching raw phrase string
  Future<bool> playPhrase(String rawPhrase) async {
    final matched = SignLanguagePhraseRegistry.findPhrase(rawPhrase);
    if (matched == null) {
      _statusMessage = "I don't have a sign for that phrase yet.";
      debugPrint('[SIGN_TRACE] phrase=$rawPhrase animation=NONE available=false');
      return false;
    }
    return playAnimation(matched.animationName, phrase: matched);
  }

  /// Play specific animation by named clip
  Future<bool> playAnimation(String animationName, {SignLanguagePhrase? phrase}) async {
    _activePhrase = phrase ??
        SignLanguagePhraseRegistry.phrases.firstWhere(
          (p) => p.animationName == animationName,
          orElse: () => SignLanguagePhrase(
            id: animationName.toLowerCase(),
            displayText: animationName,
            aliases: [animationName.toLowerCase()],
            animationName: animationName,
          ),
        );

    _statusMessage = "Playing sign for: ${_activePhrase!.displayText}";
    _isPlaying = true;
    _isPaused = false;

    debugPrint('[SIGN_TRACE] phrase=${_activePhrase!.displayText} animation=$animationName');

    if (_controller != null) {
      try {
        if (_controller!.onModelLoaded.value) {
          final available = await _controller!.getAvailableAnimations();
          if (available.contains(animationName)) {
            _controller!.playAnimation(animationName: animationName);
            debugPrint('[SIGN_TRACE] phrase=${_activePhrase!.displayText} animation=$animationName available=true');
            return true;
          } else {
            _isPlaying = false;
            _statusMessage = "Sign animation not available yet.";
            debugPrint('[SIGN_TRACE] phrase=${_activePhrase!.displayText} animation=$animationName available=false');
            return false;
          }
        } else {
          _isPlaying = false;
          _statusMessage = "Sign animation not available yet.";
          debugPrint('[SIGN_TRACE] 3D model not loaded yet');
          return false;
        }
      } catch (e) {
        debugPrint('[SIGN_TRACE] 3D playback exception: $e');
        _isPlaying = false;
        _statusMessage = "Sign animation not available yet.";
        return false;
      }
    }

    // Headless test fallback (when no controller attached)
    return true;
  }

  void pause() {
    if (!_isPlaying) return;
    _isPaused = true;
    _statusMessage = "Paused";
    debugPrint('[SIGN_TRACE] animation paused');
    try {
      _controller?.pauseAnimation();
    } catch (_) {}
  }

  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _isPlaying = true;
    _statusMessage = "Resumed";
    debugPrint('[SIGN_TRACE] animation resumed');
    try {
      _controller?.playAnimation();
    } catch (_) {}
  }

  void replay() {
    if (_activePhrase != null) {
      playAnimation(_activePhrase!.animationName, phrase: _activePhrase);
    }
  }

  void stop() {
    _isPlaying = false;
    _isPaused = false;
    _statusMessage = null;
    debugPrint('[SIGN_TRACE] animation stopped');
    try {
      _controller?.stopAnimation();
    } catch (_) {}
  }
}
