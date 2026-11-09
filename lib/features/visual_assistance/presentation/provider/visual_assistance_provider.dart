import '../../../../core/di/service_locator.dart';
import '../../../../features/speech_assistance/presentation/provider/global_voice_control_provider.dart';
import '../../../../core/services/stt_service.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../data/datasources/ml_kit_ocr_service.dart';
import '../../data/datasources/yolo_tflite_service.dart';
import '../../data/datasources/adiuva_object_classifier_service.dart';
import '../../data/datasources/ml_kit_barcode_service.dart';
import '../../data/datasources/scene_description_service.dart';
import '../../data/datasources/document_reader_service.dart';
import '../../domain/entities/vision_result.dart';
import '../../domain/entities/document_reader_entity.dart';

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
  final AdiuvaObjectClassifierService _objectClassifierService;
  final MlKitBarcodeService _barcodeService;
  final SceneDescriptionService _sceneService;
  final TtsService _ttsService;
  final DocumentReaderService _documentReaderService;

  VisionMode _currentMode = VisionMode.describeScene;
  VisionStateEnum _state = VisionStateEnum.idle;
  VisionResult? _lastResult;
  String? _errorMessage;

  // Continuous Object Recognition & Smart Announcement State
  static const double defaultConfidenceThreshold = 0.70;
  static const Duration repeatAnnouncementInterval = Duration(seconds: 10);
  static const Duration disappearanceGracePeriod = Duration(milliseconds: 2000);
  static const Duration frameThrottleInterval = Duration(milliseconds: 500);

  double _confidenceThreshold = defaultConfidenceThreshold;
  bool _isContinuousMonitoring = false;
  String? _currentIdentifiedClass;
  DateTime? _currentObjectFirstSeen;
  DateTime? _currentObjectLastSeen;
  DateTime? _lastAnnouncementTime;
  DateTime? _lastFrameProcessedTime;

  // Real-Time Bounding Boxes & Streaming State
  List<DetectedObjectBox> _liveBoundingBoxes = [];
  bool _isDetectingFrame = false;

  // Multi-Page Document Reader State
  DocumentBook? _activeDocument;
  bool _isReadingDocument = false;
  bool _isDocumentPaused = false;
  bool _isSummarizingDocument = false;

  // Operation ID counter to invalidate in-flight async tasks across mode switches
  int _activeOperationId = 0;

  VisualAssistanceProvider({
    required CameraService cameraService,
    required MlKitOcrService ocrService,
    required YoloTfliteService detectionService,
    required MlKitBarcodeService barcodeService,
    required SceneDescriptionService sceneService,
    required TtsService ttsService,
    DocumentReaderService? documentReaderService,
    AdiuvaObjectClassifierService? objectClassifierService,
  })  : _cameraService = cameraService,
        _ocrService = ocrService,
        _detectionService = detectionService,
        _barcodeService = barcodeService,
        _sceneService = sceneService,
        _ttsService = ttsService,
        _documentReaderService = documentReaderService ?? DocumentReaderService(ocrService: ocrService),
        _objectClassifierService = objectClassifierService ?? AdiuvaObjectClassifierService() {
    _ttsService.addCompletionListener(_onTtsFinishedReadingPage);
  }

  void _onTtsFinishedReadingPage() {
    if (_isReadingDocument && _activeDocument != null) {
      if (_activeDocument!.hasNextPage) {
        Future.microtask(() => nextPage());
      } else {
        _isReadingDocument = false;
        _isDocumentPaused = false;
        notifyListeners();
        _ttsService.speak('End of document.');
      }
    }
  }

  VisionMode get currentMode => _currentMode;
  VisionStateEnum get state => _state;
  VisionResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;
  CameraController? get cameraController => _cameraService.controller;
  bool get isCameraReady => _cameraService.isInitialized;
  bool get isFlashOn => _cameraService.isFlashOn;
  bool get isSpeaking => _ttsService.isSpeaking;
  List<DetectedObjectBox> get liveBoundingBoxes => _liveBoundingBoxes;
  AdiuvaObjectClassifierService get objectClassifierService => _objectClassifierService;
  YoloTfliteService get detectionService => _detectionService;

  // Continuous Object Recognition Getters
  double get confidenceThreshold => _confidenceThreshold;
  set confidenceThreshold(double value) {
    _confidenceThreshold = value;
    notifyListeners();
  }

  bool get isContinuousMonitoring => _isContinuousMonitoring;
  String? get currentIdentifiedClass => _currentIdentifiedClass;
  DateTime? get lastAnnouncementTime => _lastAnnouncementTime;
  DateTime? get currentObjectFirstSeen => _currentObjectFirstSeen;
  DateTime? get currentObjectLastSeen => _currentObjectLastSeen;

  // Multi-Page Document Getters
  DocumentBook? get activeDocument => _activeDocument;
  bool get isReadingDocument => _isReadingDocument;
  bool get isDocumentPaused => _isDocumentPaused;
  bool get isSummarizingDocument => _isSummarizingDocument;
  bool get hasActiveDocument => _activeDocument != null;

  /// Set active vision mode and invalidate in-flight async tasks
  Future<void> setMode(VisionMode mode) async {
    debugPrint('[VISION_MODE] requested = ${mode.name}');

    _activeOperationId++; // Invalidate in-flight detection
    await _ttsService.stop();

    final oldMode = _currentMode;
    _currentMode = mode;
    _lastResult = null;
    _errorMessage = null;
    _liveBoundingBoxes = [];
    _state = VisionStateEnum.ready;

    debugPrint('[VISION_MODE] active = ${_currentMode.name}');
    debugPrint('[VOICE_FLOW] opened ${_currentMode.name}');

    if (oldMode == VisionMode.identifyObject || _currentMode != VisionMode.identifyObject) {
      await stopContinuousMonitoring();
    }

    if (_currentMode == VisionMode.identifyObject) {
      await startContinuousMonitoring();
    }

    notifyListeners();
  }

  /// Start continuous camera monitoring for object recognition
  Future<void> startContinuousMonitoring() async {
    _isContinuousMonitoring = true;
    _currentIdentifiedClass = null;
    _currentObjectFirstSeen = null;
    _currentObjectLastSeen = null;
    _lastAnnouncementTime = null;
    _lastFrameProcessedTime = null;
    _candidateClass = null;
    _candidateStreak = 0;

    if (isCameraReady && _currentMode == VisionMode.identifyObject) {
      await _startLiveStreaming();
    }
    notifyListeners();
  }

  /// Stop continuous camera monitoring cleanly
  Future<void> stopContinuousMonitoring() async {
    _isContinuousMonitoring = false;
    _currentIdentifiedClass = null;
    _currentObjectFirstSeen = null;
    _currentObjectLastSeen = null;
    _lastAnnouncementTime = null;
    _lastFrameProcessedTime = null;
    _candidateClass = null;
    _candidateStreak = 0;
    await _stopLiveStreaming();
    await _ttsService.stop();
    notifyListeners();
  }

  /// Toggle continuous camera monitoring
  Future<void> toggleContinuousMonitoring() async {
    if (_isContinuousMonitoring) {
      await stopContinuousMonitoring();
    } else {
      await startContinuousMonitoring();
    }
  }

  /// Alias for setMode
  Future<void> selectMode(VisionMode mode) async {
    await setMode(mode);
  }

  Future<void> setVisionMode(VisionMode mode) async {
    await setMode(mode);
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
      if (_currentMode == VisionMode.identifyObject && _isContinuousMonitoring) {
        _startLiveStreaming();
      }
    } else {
      _state = VisionStateEnum.permissionDenied;
      _errorMessage = _cameraService.errorMessage;
    }
    notifyListeners();
  }

  /// Start continuous live camera frame streaming for real-time object recognition
  Future<void> _startLiveStreaming() async {
    if (!_cameraService.isInitialized || _cameraService.isStreaming) return;

    await _cameraService.startImageStream((CameraImage image) async {
      if (_isDetectingFrame || !_isContinuousMonitoring || _currentMode != VisionMode.identifyObject) return;

      final now = DateTime.now();
      if (_lastFrameProcessedTime != null && now.difference(_lastFrameProcessedTime!) < frameThrottleInterval) {
        return; // Controlled frame rate (2 FPS) to avoid excessive CPU and battery usage
      }
      _lastFrameProcessedTime = now;
      _isDetectingFrame = true;

      try {
        final rotation = _cameraService.sensorOrientation;

        // 1. Run Genuine YOLOv8 Detection on the live frame
        final yoloBoxes = await _detectionService.detectObjectsFromCameraImage(
          image,
          rotation: rotation,
        );
        _liveBoundingBoxes = yoloBoxes;

        if (!_isContinuousMonitoring || _currentMode != VisionMode.identifyObject) return;

        if (yoloBoxes.isNotEmpty) {
          // Multi-object spatial relationship check (e.g. "I can see a bottle beside a laptop.")
          if (yoloBoxes.length >= 2) {
            final box0 = yoloBoxes[0];
            final box1 = yoloBoxes[1];
            final double cx0 = (box0.left + box0.right) / 2.0;
            final double cy0 = (box0.top + box0.bottom) / 2.0;
            final double cx1 = (box1.left + box1.right) / 2.0;
            final double cy1 = (box1.top + box1.bottom) / 2.0;

            final double dx = (cx0 - cx1).abs();
            final double dy = (cy0 - cy1).abs();

            if (dx < 0.50 && dy < 0.35) {
              final phrase = AdiuvaObjectClassifierService.formatRelationshipPhrase(
                box0.label,
                box1.label,
                relation: 'beside',
              );
              handleContinuousMonitoringResult(
                ObjectClassificationResult(
                  label: '${box0.label}_beside_${box1.label}',
                  displayName: '${AdiuvaObjectClassifierService.formatDisplayName(box0.label)} beside ${AdiuvaObjectClassifierService.formatDisplayName(box1.label)}',
                  confidence: (box0.confidence + box1.confidence) / 2.0,
                  topAlternatives: [
                    ClassConfidence(label: box0.label, displayName: AdiuvaObjectClassifierService.formatDisplayName(box0.label), confidence: box0.confidence),
                    ClassConfidence(label: box1.label, displayName: AdiuvaObjectClassifierService.formatDisplayName(box1.label), confidence: box1.confidence),
                  ],
                  inferenceTimeMs: 20,
                ),
                customPhrase: phrase,
                requireConsensus: true,
              );
              return;
            }
          }

          // Single main YOLO object
          final mainBox = yoloBoxes[0];
          final phrase = AdiuvaObjectClassifierService.formatNaturalPhrase(
            mainBox.label,
            AdiuvaObjectClassifierService.formatDisplayName(mainBox.label),
            direction: mainBox.spatialDirection,
          );
          handleContinuousMonitoringResult(
            ObjectClassificationResult(
              label: mainBox.label,
              displayName: AdiuvaObjectClassifierService.formatDisplayName(mainBox.label),
              confidence: mainBox.confidence,
              topAlternatives: [
                ClassConfidence(label: mainBox.label, displayName: AdiuvaObjectClassifierService.formatDisplayName(mainBox.label), confidence: mainBox.confidence),
              ],
              inferenceTimeMs: 20,
            ),
            direction: mainBox.spatialDirection,
            customPhrase: phrase,
            requireConsensus: true,
          );
          return;
        }

        // 2. Fall back to 19-class fine-grained classifier when YOLO detects no boxes
        final result = await _objectClassifierService.classifyCameraImage(
          image,
          rotation: rotation,
        );

        if (!_isContinuousMonitoring || _currentMode != VisionMode.identifyObject) return;

        ObjectClassificationResult? reliableResult;
        if (result != null && result.confidence >= _confidenceThreshold) {
          // Check margin against second candidate to eliminate noise / false keyboard predictions
          final bool hasMargin = result.topAlternatives.length < 2 ||
              result.confidence >= result.topAlternatives[1].confidence * 1.25;
          if (hasMargin) {
            reliableResult = result;
          }
        }

        handleContinuousMonitoringResult(
          reliableResult,
          requireConsensus: true,
        );
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
    _isDetectingFrame = false;
    await _cameraService.stopImageStream();
    notifyListeners();
  }

  /// Check if Voice Control STT or TTS is actively in use to avoid speaking over user
  bool _isVoiceControlActive() {
    try {
      if (sl.isRegistered<GlobalVoiceControlProvider>()) {
        final voice = sl<GlobalVoiceControlProvider>();
        if (voice.isListening || voice.isSpeaking) return true;
      }
      if (sl.isRegistered<SttService>()) {
        if (sl<SttService>().isListening) return true;
      }
    } catch (_) {}
    return false;
  }

  /// Core smart announcement logic for continuous monitoring frames.
  /// Made package-visible for deterministic unit testing.
  String? _candidateClass;
  int _candidateStreak = 0;
  static const int _requiredStreak = 2; // Consensus across at least 2 consecutive frames

  /// Core smart announcement logic for continuous monitoring frames.
  /// Announces stable detections ONCE, suppresses repeated chatter, and enforces temporal consensus.
  void handleContinuousMonitoringResult(
    ObjectClassificationResult? result, {
    SpatialDirection direction = SpatialDirection.unspecified,
    DateTime? nowOverride,
    bool requireConsensus = false,
    String? customPhrase,
  }) {
    final now = nowOverride ?? DateTime.now();
    final bool isReliable = result != null && result.confidence >= _confidenceThreshold;

    if (isReliable) {
      final String detectedLabel = result.label;
      final String displayName = result.displayName;
      final phrase = customPhrase ??
          AdiuvaObjectClassifierService.formatNaturalPhrase(
            detectedLabel,
            displayName,
            direction: direction,
          );

      // Update lastResult for visual feedback and UI without speaking every frame
      _lastResult = VisionResult(
        mode: VisionMode.identifyObject,
        title: 'Live Object: $displayName',
        text: phrase,
        labels: [
          result.displayName,
          ...result.topAlternatives
              .where((a) => a.label != detectedLabel)
              .take(2)
              .map((a) => a.displayName),
        ],
        timestamp: now,
      );
      notifyListeners();

      // Check if it's the same object as currently tracked
      if (_currentIdentifiedClass == detectedLabel) {
        _currentObjectLastSeen = now;
        final shouldAnnounce = _lastAnnouncementTime == null ||
            now.difference(_lastAnnouncementTime!) >= repeatAnnouncementInterval;
        if (shouldAnnounce && !_ttsService.isSpeaking && !_isVoiceControlActive()) {
          _lastAnnouncementTime = now;
          _ttsService.speak(phrase);
        }
      } else {
        // Different object: require temporal consensus if requested
        if (requireConsensus) {
          if (_candidateClass == detectedLabel) {
            _candidateStreak++;
          } else {
            _candidateClass = detectedLabel;
            _candidateStreak = 1;
          }

          if (_candidateStreak < _requiredStreak) {
            return;
          }
        }

        _candidateClass = null;
        _candidateStreak = 0;
        _currentIdentifiedClass = detectedLabel;
        _currentObjectFirstSeen = now;
        _currentObjectLastSeen = now;

        if (!_ttsService.isSpeaking && !_isVoiceControlActive()) {
          _lastAnnouncementTime = now;
          _ttsService.speak(phrase);
        } else {
          _lastAnnouncementTime = null; // Will announce on next frame when TTS/Voice finishes
        }
      }
    } else {
      // Below threshold or no object detected in this frame
      _candidateClass = null;
      _candidateStreak = 0;

      if (_currentIdentifiedClass != null && _currentObjectLastSeen != null) {
        if (now.difference(_currentObjectLastSeen!) >= disappearanceGracePeriod) {
          // Object has disappeared beyond grace period -> clear tracked state silently
          _currentIdentifiedClass = null;
          _currentObjectFirstSeen = null;
          _currentObjectLastSeen = null;
          _lastAnnouncementTime = null;
        }
      }
    }
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
    List<DetectedObjectBox>? fallbackBoxes;
    try {
      fallbackBoxes = await _detectionService.detectObjects(imagePath);
    } catch (_) {}
    final description = await _sceneService.describeScene(imagePath, fallbackBoxes: fallbackBoxes);
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
    // 1. Run the fine-grained 19-class ADIUVA Object Classifier (MobileNetV3)
    final classification = await _objectClassifierService.classifyImage(imagePath);
    if (opId != _activeOperationId || _currentMode != requestedMode) return;

    if (classification != null && classification.confidence >= _confidenceThreshold) {
      _state = VisionStateEnum.success;

      // Check verified spatial coordinates from YOLO bounding boxes if available
      SpatialDirection verifiedDirection = SpatialDirection.unspecified;
      try {
        final yoloBoxes = await _detectionService.detectObjects(imagePath);
        _liveBoundingBoxes = yoloBoxes;
        final cleanLabel = classification.label.toLowerCase().replaceAll(' ', '_');
        for (final box in yoloBoxes) {
          final cleanBoxLabel = box.label.toLowerCase().replaceAll(' ', '_');
          if (cleanBoxLabel == cleanLabel) {
            verifiedDirection = box.spatialDirection;
            break;
          }
        }
      } catch (_) {
        // YOLO error or unverified: direction remains unspecified
      }

      final naturalDescription = AdiuvaObjectClassifierService.formatNaturalPhrase(
        classification.label,
        classification.displayName,
        direction: verifiedDirection,
      );
      _lastResult = VisionResult(
        mode: VisionMode.identifyObject,
        title: 'Object Identified: ${classification.displayName}',
        text: naturalDescription,
        labels: classification.topAlternatives
            .map((alt) => alt.displayName)
            .toList(),
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );

      _currentIdentifiedClass = classification.label;
      final now = DateTime.now();
      _currentObjectFirstSeen = now;
      _currentObjectLastSeen = now;
      _lastAnnouncementTime = now;
      return;
    }

    // Inconclusive or below threshold
    _state = VisionStateEnum.empty;
    _lastResult = VisionResult(
      mode: VisionMode.identifyObject,
      title: 'No Reliable Object Identified',
      text: 'No reliable object was identified. Please ensure good lighting and try again.',
      labels: classification != null
          ? classification.topAlternatives
              .map((alt) => alt.displayName)
              .toList()
          : const [],
      timestamp: DateTime.now(),
      imagePath: imagePath,
    );
  }

  /// Pick an image from device storage/gallery and identify the object using the ADIUVA classifier
  Future<void> pickAndIdentifyObject() async {
    final currentOpId = ++_activeOperationId;
    final requestedMode = VisionMode.identifyObject;

    await _ttsService.stop();
    _currentMode = VisionMode.identifyObject;
    _state = VisionStateEnum.processing;
    _lastResult = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final PlatformFile? pickedFile = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (pickedFile == null || pickedFile.path == null) {
        _state = VisionStateEnum.ready;
        notifyListeners();
        return;
      }

      final imagePath = pickedFile.path!;
      await _processObjectDetection(imagePath, currentOpId, requestedMode);

      if (currentOpId != _activeOperationId || _currentMode != requestedMode) return;

      notifyListeners();

      if (_lastResult != null && _lastResult!.mode == _currentMode && _lastResult!.text.isNotEmpty) {
        await _ttsService.speak(_lastResult!.text);
      }
    } catch (e) {
      if (currentOpId != _activeOperationId || _currentMode != requestedMode) return;
      _state = VisionStateEnum.error;
      _errorMessage = 'Failed to select image from storage: ${e.toString().replaceAll("Exception: ", "")}';
      notifyListeners();
    }
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
    _isReadingDocument = false;
    _isDocumentPaused = false;
    notifyListeners();
  }

  /// Import a document (PDF, JPG, PNG) from device storage
  Future<void> importDocument() async {
    try {
      await _ttsService.stop();
      _isReadingDocument = false;
      _isDocumentPaused = false;
      _state = VisionStateEnum.processing;
      notifyListeners();

      final doc = await _documentReaderService.pickAndExtractDocument();
      if (doc == null) {
        _state = VisionStateEnum.ready;
        notifyListeners();
        return;
      }

      _activeDocument = doc;
      _currentMode = VisionMode.readText;
      _state = VisionStateEnum.success;

      _lastResult = VisionResult(
        mode: VisionMode.readText,
        title: 'Document: ${doc.fileName} (Page 1 of ${doc.totalPages})',
        text: doc.currentPageText,
        timestamp: DateTime.now(),
        imagePath: doc.filePath,
      );

      notifyListeners();

      final String announcement =
          'Document ${doc.fileName} loaded. Page 1 of ${doc.totalPages}. Say start reading or tap play to read aloud.';
      await _ttsService.speak(announcement);
    } catch (e) {
      _state = VisionStateEnum.error;
      _errorMessage = 'Failed to load document: ${e.toString().replaceAll("Exception: ", "")}';
      notifyListeners();
    }
  }

  /// Read current active document page aloud
  Future<void> startReadingDocument() async {
    if (_activeDocument == null || _activeDocument!.currentPageText.isEmpty) return;

    _isReadingDocument = true;
    _isDocumentPaused = false;
    notifyListeners();

    await _ttsService.stop();
    await _ttsService.speak(_activeDocument!.currentPageText);
  }

  /// Pause document read aloud playback
  Future<void> pauseReadingDocument() async {
    _isReadingDocument = false;
    _isDocumentPaused = true;
    await _ttsService.stop();
    notifyListeners();
    await _ttsService.speak('Reading paused.');
  }

  /// Resume document read aloud playback
  Future<void> resumeReadingDocument() async {
    if (_activeDocument == null) return;
    _isReadingDocument = true;
    _isDocumentPaused = false;
    notifyListeners();

    await _ttsService.stop();
    await _ttsService.speak(_activeDocument!.currentPageText);
  }

  /// Stop document read aloud playback
  Future<void> stopReadingDocument() async {
    _isReadingDocument = false;
    _isDocumentPaused = false;
    await _ttsService.stop();
    notifyListeners();
  }

  /// Navigate to next page in multi-page document
  Future<void> nextPage() async {
    if (_activeDocument == null || !_activeDocument!.hasNextPage) return;

    await _ttsService.stop();
    final newIndex = _activeDocument!.currentPageIndex + 1;
    _activeDocument = _activeDocument!.copyWith(currentPageIndex: newIndex);

    _lastResult = VisionResult(
      mode: VisionMode.readText,
      title: 'Document: ${_activeDocument!.fileName} (Page ${newIndex + 1} of ${_activeDocument!.totalPages})',
      text: _activeDocument!.currentPageText,
      timestamp: DateTime.now(),
      imagePath: _activeDocument!.filePath,
    );

    notifyListeners();

    final String pageAnnouncement = 'Page ${newIndex + 1} of ${_activeDocument!.totalPages}.';
    await _ttsService.speak(pageAnnouncement);

    if (_isReadingDocument) {
      await Future.delayed(const Duration(milliseconds: 600));
      await _ttsService.speak(_activeDocument!.currentPageText);
    }
  }

  /// Navigate to previous page in multi-page document
  Future<void> previousPage() async {
    if (_activeDocument == null || !_activeDocument!.hasPreviousPage) return;

    await _ttsService.stop();
    final newIndex = _activeDocument!.currentPageIndex - 1;
    _activeDocument = _activeDocument!.copyWith(currentPageIndex: newIndex);

    _lastResult = VisionResult(
      mode: VisionMode.readText,
      title: 'Document: ${_activeDocument!.fileName} (Page ${newIndex + 1} of ${_activeDocument!.totalPages})',
      text: _activeDocument!.currentPageText,
      timestamp: DateTime.now(),
      imagePath: _activeDocument!.filePath,
    );

    notifyListeners();

    final String pageAnnouncement = 'Page ${newIndex + 1} of ${_activeDocument!.totalPages}.';
    await _ttsService.speak(pageAnnouncement);

    if (_isReadingDocument) {
      await Future.delayed(const Duration(milliseconds: 600));
      await _ttsService.speak(_activeDocument!.currentPageText);
    }
  }

  /// Update active document page index from manual PDF viewer scroll
  void updateActiveDocumentPageIndex(int newIndex) {
    if (_activeDocument == null) return;
    if (newIndex < 0 || newIndex >= _activeDocument!.totalPages) return;
    if (_activeDocument!.currentPageIndex == newIndex) return;

    _activeDocument = _activeDocument!.copyWith(currentPageIndex: newIndex);

    _lastResult = VisionResult(
      mode: VisionMode.readText,
      title: 'Document: ${_activeDocument!.fileName} (Page ${newIndex + 1} of ${_activeDocument!.totalPages})',
      text: _activeDocument!.currentPageText,
      timestamp: DateTime.now(),
      imagePath: _activeDocument!.filePath,
    );

    notifyListeners();
  }

  /// Generate AI story summary using Gemini AI
  Future<void> summarizeActiveDocument() async {
    if (_activeDocument == null) return;

    if (_activeDocument!.summary != null && _activeDocument!.summary!.isNotEmpty) {
      await _ttsService.speak('Story Summary: ${_activeDocument!.summary}');
      return;
    }

    _isSummarizingDocument = true;
    notifyListeners();

    await _ttsService.speak('Summarizing story with AI. Please wait.');

    try {
      final summary = await _documentReaderService.summarizeDocument(_activeDocument!);
      _activeDocument = _activeDocument!.copyWith(summary: summary);
      _isSummarizingDocument = false;
      notifyListeners();

      await _ttsService.speak('Story Summary: $summary');
    } catch (e) {
      _isSummarizingDocument = false;
      notifyListeners();
      await _ttsService.speak('Could not summarize document at this time.');
    }
  }

  /// Clear current loaded document
  void clearDocument() {
    stopReadingDocument();
    _activeDocument = null;
    notifyListeners();
  }

  Future<void> disposeCamera() async {
    _activeOperationId++;
    await _stopLiveStreaming();
    await _cameraService.disposeCamera();
    _state = VisionStateEnum.idle;
    _lastResult = null;
    _activeDocument = null;
    _isReadingDocument = false;
    _isDocumentPaused = false;
    notifyListeners();
  }
}
