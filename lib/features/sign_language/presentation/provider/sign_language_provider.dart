import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../../../../core/services/tts_service.dart';
import '../../data/datasources/isl_tflite_service.dart';
import '../../data/registries/sign_language_phrase_registry.dart';
import '../../data/services/sign_language_animation_service.dart';
import '../../domain/entities/isl_avatar_character.dart';
import '../../domain/entities/sign_language_phrase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SignLanguageMode {
  signToText,
  textToSign,
}

/// Central Provider managing Two-Way Indian Sign Language (ISL) Conversion
class SignLanguageProvider extends ChangeNotifier {
  final SignLanguageAnimationService _animationService = SignLanguageAnimationService();
  final IslTfliteService _islTfliteService = IslTfliteService();
  final TtsService _ttsService = TtsService();
  Flutter3DController _flutter3dController = Flutter3DController();
  Flutter3DController get flutter3dController => _flutter3dController;

  SignLanguageMode _currentMode = SignLanguageMode.signToText;
  String _searchQuery = '';
  SignLanguagePhrase? _selectedPhrase;
  String? _feedbackMessage;

  // Avatar Character Selection (Male - Aarav, Female - Ananya)
  IslAvatarCharacter _selectedCharacter = IslAvatarCharacter.male;
  bool _hasSelectedAvatar = false;

  // Direction A: Sign -> Text (Camera ML State)
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isRecognizing = false;
  bool _isFrameProcessing = false;
  DateTime _lastFrameTime = DateTime.now();

  RecognizedSignResult? _lastRecognizedResult;
  final List<String> _transcriptHistory = [];

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  SignLanguageProvider() {
    _animationService.attachController(flutter3dController);
    _selectedPhrase = SignLanguagePhraseRegistry.phrases.first;
    _loadSavedAvatarPreference();
  }

  Future<void> _loadSavedAvatarPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('adiuva_isl_selected_avatar');
      if (savedId != null) {
        _selectedCharacter = IslAvatarCharacter.fromId(savedId);
        _hasSelectedAvatar = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ISL_AVATAR] Error loading saved avatar preference: $e');
    }
  }

  void recreate3DController() {
    try {
      _animationService.detachController();
    } catch (_) {}
    _flutter3dController = Flutter3DController();
    _animationService.attachController(_flutter3dController);
    debugPrint('[ISL_AVATAR] Fresh Flutter3DController created for 3D model: ${_selectedCharacter.assetPath}');
    notifyListeners();
  }

  Future<void> selectCharacter(IslAvatarCharacter character) async {
    _selectedCharacter = character;
    _hasSelectedAvatar = true;
    _feedbackMessage = "Active avatar: ${character.name}";
    recreate3DController();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adiuva_isl_selected_avatar', character.id);
    } catch (e) {
      debugPrint('[ISL_AVATAR] Error saving avatar preference: $e');
    }
  }

  // Getters
  IslAvatarCharacter get selectedCharacter => _selectedCharacter;
  bool get hasSelectedAvatar => _hasSelectedAvatar;
  SignLanguageMode get currentMode => _currentMode;
  SignLanguagePhrase? get selectedPhrase => _selectedPhrase ?? _animationService.activePhrase;
  bool get isPlaying => _animationService.isPlaying;
  bool get isPaused => _animationService.isPaused;
  String? get feedbackMessage => _feedbackMessage ?? _animationService.statusMessage;
  String get searchQuery => _searchQuery;

  // Camera & Recognition Getters
  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isRecognizing => _isRecognizing;
  RecognizedSignResult? get lastRecognizedResult => _lastRecognizedResult;
  List<String> get transcriptHistory => List.unmodifiable(_transcriptHistory);
  String get accumulatedTranscript => _transcriptHistory.join(' ');

  List<SignLanguagePhrase> get filteredPhrases {
    if (_searchQuery.trim().isEmpty) {
      return SignLanguagePhraseRegistry.phrases;
    }
    final clean = SignLanguagePhraseRegistry.normalize(_searchQuery);
    return SignLanguagePhraseRegistry.phrases.where((p) {
      final cleanTitle = SignLanguagePhraseRegistry.normalize(p.displayText);
      if (cleanTitle.contains(clean)) return true;
      for (final a in p.aliases) {
        if (SignLanguagePhraseRegistry.normalize(a).contains(clean)) return true;
      }
      return false;
    }).toList();
  }

  void setMode(SignLanguageMode mode) {
    _currentMode = mode;
    if (mode == SignLanguageMode.textToSign && _isRecognizing) {
      stopCameraRecognition();
    }
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ==================== DIRECTION A: SIGN -> TEXT ====================

  Future<void> initializeCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        _isCameraInitialized = false;
        notifyListeners();
        return;
      }

      // Default to front camera for Sign Language input
      final frontCamIndex = _availableCameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIndex = frontCamIndex != -1 ? frontCamIndex : 0;

      await _setupCameraController(_availableCameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('[SIGN_CAMERA] Initialization error: $e');
      _isCameraInitialized = false;
      notifyListeners();
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
      _isCameraInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[SIGN_CAMERA] Setup error: $e');
      _isCameraInitialized = false;
      notifyListeners();
    }
  }

  Future<void> toggleCameraLens() async {
    if (_availableCameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    final wasRecognizing = _isRecognizing;
    if (wasRecognizing) {
      await stopCameraRecognition();
    }
    await _setupCameraController(_availableCameras[_selectedCameraIndex]);
    if (wasRecognizing) {
      await startCameraRecognition();
    }
  }

  Future<void> startCameraRecognition() async {
    if (!_isCameraInitialized || _cameraController == null) {
      await initializeCamera();
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _isRecognizing = true;
    _islTfliteService.resetTemporalBuffer();
    _feedbackMessage = "Live recognition active. Perform ISL sign.";
    notifyListeners();

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (!_isRecognizing || _isFrameProcessing) return;

        // Throttling: process camera frame at most once every 350ms for mobile performance
        final now = DateTime.now();
        if (now.difference(_lastFrameTime).inMilliseconds < 350) return;

        _isFrameProcessing = true;
        _lastFrameTime = now;

        try {
          // Construct InputImage from camera stream byte planes
          final WriteBuffer allBytes = WriteBuffer();
          for (final Plane plane in image.planes) {
            allBytes.putUint8List(plane.bytes);
          }
          final bytes = allBytes.done().buffer.asUint8List();

          final InputImageMetadata metadata = InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21,
            bytesPerRow: image.planes.first.bytesPerRow,
          );

          final inputImage = InputImage.fromBytes(
            bytes: bytes,
            metadata: metadata,
          );

          final result = await _islTfliteService.processCameraFrame(inputImage);
          if (result != null && result.confidence >= 0.70) {
            _lastRecognizedResult = result;
            _transcriptHistory.add(result.signName);
            _feedbackMessage = "Recognized: ${result.signName} (${(result.confidence * 100).toInt()}%)";
            debugPrint('[ISL_RECOGNITION] Recognized sign: ${result.signName} (confidence: ${result.confidence})');
            notifyListeners();
          }
        } catch (e) {
          debugPrint('[SIGN_CAMERA] Frame processing note: $e');
        } finally {
          _isFrameProcessing = false;
        }
      });
    } catch (e) {
      debugPrint('[SIGN_CAMERA] Image stream error: $e');
    }
  }

  Future<void> stopCameraRecognition() async {
    _isRecognizing = false;
    _feedbackMessage = "Camera recognition stopped.";
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> speakTranscript() async {
    final text = accumulatedTranscript;
    if (text.trim().isNotEmpty) {
      await _ttsService.speak(text);
      _feedbackMessage = "Speaking transcript: $text";
      notifyListeners();
    }
  }

  void clearTranscript() {
    _transcriptHistory.clear();
    _lastRecognizedResult = null;
    _feedbackMessage = "Transcript cleared.";
    notifyListeners();
  }

  // ==================== DIRECTION B: TEXT / VOICE -> SIGN ====================

  Future<void> selectAndPlayPhrase(SignLanguagePhrase phrase) async {
    _selectedPhrase = phrase;
    _feedbackMessage = "Playing sign for: ${phrase.displayText}";
    notifyListeners();

    final success = await _animationService.playAnimation(phrase.animationName, phrase: phrase);
    if (!success) {
      _feedbackMessage = "Sign animation not available yet.";
    }
    notifyListeners();
  }

  Future<void> playPhraseByText(String text) async {
    final matched = SignLanguagePhraseRegistry.findPhrase(text);
    if (matched != null) {
      await selectAndPlayPhrase(matched);
    } else {
      _feedbackMessage = "This phrase is not currently supported.";
      debugPrint('[SIGN_TRACE] phrase=$text animation=NONE available=false');
      notifyListeners();
    }
  }

  void pause() {
    _animationService.pause();
    _feedbackMessage = "Paused";
    notifyListeners();
  }

  void resume() {
    _animationService.resume();
    _feedbackMessage = "Playing sign for: ${_selectedPhrase?.displayText ?? ''}";
    notifyListeners();
  }

  void replay() {
    _animationService.replay();
    _feedbackMessage = "Replaying sign for: ${_selectedPhrase?.displayText ?? ''}";
    notifyListeners();
  }

  void stop() {
    _animationService.stop();
    _feedbackMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_isRecognizing) {
      stopCameraRecognition();
    }
    _cameraController?.dispose();
    _islTfliteService.dispose();
    _animationService.detachController();
    super.dispose();
  }
}
