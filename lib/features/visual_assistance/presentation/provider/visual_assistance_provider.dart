import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../data/datasources/ml_kit_ocr_service.dart';
import '../../data/datasources/yolo_tflite_service.dart';
import '../../data/datasources/ml_kit_barcode_service.dart';
import '../../data/datasources/scene_description_service.dart';
import '../../domain/entities/vision_result.dart';

/// Explicit State Model for Vision Features
enum VisionStateEnum {
  idle,
  initializing,
  ready,
  capturing,
  processing,
  success,
  empty,
  error,
  permissionDenied,
}

/// Provider managing Camera lifecycle, Real-Time YOLO Streaming, and TTS readout
class VisualAssistanceProvider extends ChangeNotifier {
  final CameraService _cameraService;
  final MlKitOcrService _ocrService;
  final YoloTfliteService _detectionService;
  final MlKitBarcodeService _barcodeService;
  final SceneDescriptionService _sceneService;
  final TtsService _ttsService;

  VisionMode _currentMode = VisionMode.describeScene;
  VisionStateEnum _state = VisionStateEnum.idle;
  VisionResult? _lastResult;
  String? _errorMessage;

  // Real-Time YOLO Bounding Boxes & Streaming State
  List<DetectedObjectBox> _liveBoundingBoxes = [];
  bool _isDetectingFrame = false;
  final List<List<String>> _detectionHistory = [];
  List<String> _lastSpokenClasses = [];
  DateTime? _lastSpeechTime;

  // Operation ID counter to invalidate in-flight async tasks across mode switches
  int _activeOperationId = 0;

  VisualAssistanceProvider({
    required CameraService cameraService,
    required MlKitOcrService ocrService,
    required YoloTfliteService detectionService,
    required MlKitBarcodeService barcodeService,
    required SceneDescriptionService sceneService,
    required TtsService ttsService,
  })  : _cameraService = cameraService,
        _ocrService = ocrService,
        _detectionService = detectionService,
        _barcodeService = barcodeService,
        _sceneService = sceneService,
        _ttsService = ttsService;

  VisionMode get currentMode => _currentMode;
  VisionStateEnum get state => _state;
  VisionResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;
  CameraController? get cameraController => _cameraService.controller;
  bool get isCameraReady => _cameraService.isInitialized;
  bool get isFlashOn => _cameraService.isFlashOn;
  bool get isSpeaking => _ttsService.isSpeaking;
  List<DetectedObjectBox> get liveBoundingBoxes => _liveBoundingBoxes;

  /// Set active vision mode and invalidate in-flight async tasks
  void setMode(VisionMode mode) {
    if (_currentMode == mode) return;

    final oldMode = _currentMode;
    _activeOperationId++; // Invalidate in-flight detection
    _currentMode = mode;
    _lastResult = null;
    _errorMessage = null;
    _state = VisionStateEnum.ready;

    if (oldMode == VisionMode.identifyObject) {
      _stopLiveStreaming();
    }

    if (_currentMode == VisionMode.identifyObject && isCameraReady) {
      _startLiveStreaming();
    }

    notifyListeners();
  }

  /// Alias for setMode
  void selectMode(VisionMode mode) {
    setMode(mode);
  }

  /// Toggle camera flash/torch
  Future<void> toggleFlash() async {
    await _cameraService.toggleFlash();
    notifyListeners();
  }

  /// Clear active vision result
  void clearResult() {
    _lastResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Open app settings for camera permissions
  Future<void> openSettings() async {
    await _cameraService.openSettings();
  }

  /// Initialize camera hardware
  Future<void> initializeCamera() async {
    _state = VisionStateEnum.initializing;
    notifyListeners();

    await _cameraService.initializeCamera();

    if (_cameraService.state == CameraState.ready) {
      _state = VisionStateEnum.ready;
      if (_currentMode == VisionMode.identifyObject) {
        _startLiveStreaming();
      }
    } else {
      _state = VisionStateEnum.permissionDenied;
      _errorMessage = _cameraService.errorMessage;
    }
    notifyListeners();
  }

  /// Start continuous live camera frame streaming for real-time YOLO object detection
  Future<void> _startLiveStreaming() async {
    if (!_cameraService.isInitialized || _cameraService.isStreaming) return;

    _detectionHistory.clear();
    _lastSpokenClasses.clear();
    _lastSpeechTime = null;

    await _cameraService.startImageStream((CameraImage image) async {
      if (_isDetectingFrame || _currentMode != VisionMode.identifyObject) return;

      _isDetectingFrame = true;
      try {
        final rotation = _cameraService.sensorOrientation;
        final boxes = await _detectionService.detectObjectsFromCameraImage(image, rotation: rotation);

        if (_currentMode != VisionMode.identifyObject) return;

        _liveBoundingBoxes = boxes;
        _stabilizeAndAnnounceDetections(boxes);
        notifyListeners();
      } catch (e) {
        debugPrint('[VisualAssistanceProvider] Live frame processing error: $e');
      } finally {
        _isDetectingFrame = false;
      }
    });
  }

  /// Stop continuous live camera streaming
  Future<void> _stopLiveStreaming() async {
    _liveBoundingBoxes = [];
    _detectionHistory.clear();
    await _cameraService.stopImageStream();
    notifyListeners();
  }

  /// Temporally stabilize detections across frames & debounce natural language speech announcements
  void _stabilizeAndAnnounceDetections(List<DetectedObjectBox> boxes) {
    final currentFrameClasses = boxes
        .map((b) => b.label.replaceAll('_', ' ').toLowerCase().trim())
        .where((l) => l.isNotEmpty)
        .toSet()
        .toList();

    // Maintain a sliding window of the last 4 consecutive inference frames (~400 ms window)
    _detectionHistory.add(currentFrameClasses);
    if (_detectionHistory.length > 4) {
      _detectionHistory.removeAt(0);
    }

    // Require an object to be detected in at least 3 out of the last 4 frames (~300-400ms confirmation)
    final Map<String, int> counts = {};
    for (final frameClasses in _detectionHistory) {
      for (final cls in frameClasses) {
        counts[cls] = (counts[cls] ?? 0) + 1;
      }
    }

    final List<String> confirmedVoiceClasses = counts.entries
        .where((entry) => entry.value >= 3 && _detectionHistory.length >= 3)
        .map((entry) => entry.key)
        .toList()
      ..sort();

    // Clear forgotten objects from spoken history if absent across the confirmation window
    _lastSpokenClasses.removeWhere((cls) => !counts.containsKey(cls) || (counts[cls] ?? 0) < 1);

    if (confirmedVoiceClasses.isEmpty) return;

    final bool classesChanged = !_listEquals(confirmedVoiceClasses, _lastSpokenClasses);
    final now = DateTime.now();
    final bool timeElapsed = _lastSpeechTime == null || now.difference(_lastSpeechTime!) > const Duration(seconds: 2);

    if (classesChanged && timeElapsed && !_ttsService.isSpeaking) {
      _lastSpokenClasses = List.from(confirmedVoiceClasses);
      _lastSpeechTime = now;

      final String naturalText = _formatClassesToNaturalSentence(confirmedVoiceClasses);
      _lastResult = VisionResult(
        mode: VisionMode.identifyObject,
        title: 'Live Objects Identified',
        text: naturalText,
        labels: confirmedVoiceClasses,
        timestamp: now,
      );

      _ttsService.speak(naturalText);
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _formatClassesToNaturalSentence(List<String> classes) {
    if (classes.isEmpty) return 'No distinct objects recognized in frame.';
    if (classes.length == 1) return 'I can see ${_withArticle(classes[0])}.';
    if (classes.length == 2) return 'I can see ${_withArticle(classes[0])} and ${_withArticle(classes[1])}.';
    final copy = List<String>.from(classes);
    final last = copy.removeLast();
    return 'I can see ${copy.map((l) => _withArticle(l)).join(', ')}, and ${_withArticle(last)}.';
  }

  /// Capture frame and execute active vision pipeline (Manual capture / fallback)
  Future<void> processCurrentVisionMode() async {
    if (!isCameraReady) {
      await initializeCamera();
      if (!isCameraReady) return;
    }

    final currentOpId = ++_activeOperationId;
    final requestedMode = _currentMode;

    _state = VisionStateEnum.capturing;
    _lastResult = null;
    notifyListeners();

    final XFile? capturedFile = await _cameraService.takePicture();
    if (currentOpId != _activeOperationId || _currentMode != requestedMode) {
      return; // Abort if mode changed
    }

    if (capturedFile == null) {
      _state = VisionStateEnum.error;
      _errorMessage = 'Failed to capture frame from camera.';
      notifyListeners();
      return;
    }

    _state = VisionStateEnum.processing;
    notifyListeners();

    try {
      switch (requestedMode) {
        case VisionMode.describeScene:
          await _processSceneDescription(capturedFile.path, currentOpId, requestedMode);
          break;
        case VisionMode.readText:
          await _processOcrText(capturedFile.path, currentOpId, requestedMode);
          break;
        case VisionMode.identifyObject:
          await _processObjectDetection(capturedFile.path, currentOpId, requestedMode);
          break;
        case VisionMode.scanCode:
          await _processScanCode(capturedFile.path, currentOpId, requestedMode);
          break;
      }
    } catch (e) {
      if (currentOpId != _activeOperationId || _currentMode != requestedMode) return;
      _state = VisionStateEnum.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    if (currentOpId != _activeOperationId || _currentMode != requestedMode) return;

    notifyListeners();

    if (_lastResult != null && _lastResult!.mode == _currentMode && _lastResult!.text.isNotEmpty) {
      await _ttsService.speak(_lastResult!.text);
    }
  }

  Future<void> captureAndProcess() async {
    await processCurrentVisionMode();
  }

  Future<void> _processSceneDescription(String imagePath, int opId, VisionMode requestedMode) async {
    final description = await _sceneService.describeScene(imagePath);
    if (opId != _activeOperationId || _currentMode != requestedMode) return;

    _state = VisionStateEnum.success;
    _lastResult = VisionResult(
      mode: VisionMode.describeScene,
      title: 'Scene Description',
      text: description,
      timestamp: DateTime.now(),
      imagePath: imagePath,
    );
  }

  Future<void> _processOcrText(String imagePath, int opId, VisionMode requestedMode) async {
    final text = await _ocrService.extractText(imagePath);
    if (opId != _activeOperationId || _currentMode != requestedMode) return;

    if (text.isEmpty) {
      _state = VisionStateEnum.empty;
      _lastResult = VisionResult(
        mode: VisionMode.readText,
        title: 'No Text Found',
        text: 'No readable text was detected in the frame.',
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );
    } else {
      _state = VisionStateEnum.success;
      _lastResult = VisionResult(
        mode: VisionMode.readText,
        title: 'Extracted Text',
        text: text,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );
    }
  }

  Future<void> _processObjectDetection(String imagePath, int opId, VisionMode requestedMode) async {
    final boxes = await _detectionService.detectObjects(imagePath);
    if (opId != _activeOperationId || _currentMode != requestedMode) return;

    if (boxes.isEmpty) {
      _state = VisionStateEnum.empty;
      _lastResult = VisionResult(
        mode: VisionMode.identifyObject,
        title: 'No Objects Identified',
        text: 'No distinct objects recognized in frame.',
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );
    } else {
      _state = VisionStateEnum.success;
      final naturalDescription = _formatClassesToNaturalSentence(boxes.map((b) => b.label).toList());
      _lastResult = VisionResult(
        mode: VisionMode.identifyObject,
        title: 'Objects Identified',
        text: naturalDescription,
        labels: boxes.map((b) => b.label).toList(),
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );
    }
  }

  String _withArticle(String word) {
    final w = word.trim();
    if (w.isEmpty) return w;
    if (w.startsWith('a ') || w.startsWith('an ')) return w;
    final firstChar = w[0].toLowerCase();
    if (['a', 'e', 'i', 'o', 'u'].contains(firstChar)) {
      return 'an $w';
    }
    return 'a $w';
  }

  Future<void> _processScanCode(String imagePath, int opId, VisionMode requestedMode) async {
    final result = await _barcodeService.scanBarcode(imagePath);
    if (opId != _activeOperationId || _currentMode != requestedMode) return;

    if (result == null || result.rawValue.isEmpty) {
      _state = VisionStateEnum.empty;
      _lastResult = VisionResult(
        mode: VisionMode.scanCode,
        title: 'No Code Detected',
        text: 'No QR code or barcode was detected in frame.',
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );
    } else {
      _state = VisionStateEnum.success;
      _lastResult = VisionResult(
        mode: VisionMode.scanCode,
        title: 'Code Scanned (${result.actionLabel})',
        text: result.rawValue,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );

      if (result.actionLabel == 'Website Link') {
        await _ttsService.speak('QR code detected. Opening website link now.');
        await _barcodeService.launchBarcodeContent(result.rawValue);
      }
    }
  }

  Future<void> speakResult() async {
    if (_lastResult != null && _lastResult!.text.isNotEmpty) {
      await _ttsService.speak(_lastResult!.text);
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    notifyListeners();
  }

  Future<void> disposeCamera() async {
    _activeOperationId++;
    await _stopLiveStreaming();
    await _cameraService.disposeCamera();
    _state = VisionStateEnum.idle;
    _lastResult = null;
    notifyListeners();
  }
}
