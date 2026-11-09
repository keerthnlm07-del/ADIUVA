import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../registries/sign_language_phrase_registry.dart';

/// ISL Recognized Sign Result Entity
class RecognizedSignResult {
  final String signName;
  final String phraseId;
  final double confidence;
  final String category; // 'Phrase' or 'Word'
  final DateTime timestamp;

  RecognizedSignResult({
    required this.signName,
    required this.phraseId,
    required this.confidence,
    required this.category,
    required this.timestamp,
  });
}

/// ISL Recognition Status Enum
enum SequenceRecognitionStatus {
  success,
  noFrames,
  noLandmarksDetected,
  lowConfidence,
  error,
}

/// Detailed ISL Sequence Recognition Result with diagnostic context
class DetailedSignRecognitionResult {
  final SequenceRecognitionStatus status;
  final RecognizedSignResult? result;
  final String? signName;
  final String? phraseId;
  final double confidence;
  final int totalFrames;
  final int validFrames;
  final String? topCandidate;
  final double? topCandidateConfidence;
  final String message;

  const DetailedSignRecognitionResult({
    required this.status,
    this.result,
    this.signName,
    this.phraseId,
    this.confidence = 0.0,
    required this.totalFrames,
    required this.validFrames,
    this.topCandidate,
    this.topCandidateConfidence,
    required this.message,
  });

  bool get isSuccess => status == SequenceRecognitionStatus.success;
}

/// Real Indian Sign Language (ISL) Recognition Pipeline Service
class IslTfliteService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  double confidenceThreshold = 0.70;

  // Temporal smoothing sliding window buffer (last 5 predictions)
  final List<String> _predictionHistory = [];
  String? _lastEmittedSign;
  DateTime? _lastEmittedTime;

  bool get isModelLoaded => _isModelLoaded;
  List<String> get labels => List.unmodifiable(_labels);

  /// Initialize and load verified INCLUDE-50 TFLite Model and Labels
  Future<bool> initializeModel() async {
    if (_isModelLoaded && _interpreter != null) return true;

    try {
      // 1. Load labels mapping file
      final labelsData = await rootBundle.loadString('assets/models/sign_language/isl_labels.txt');
      _labels = labelsData.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

      // 2. Load TFLite Model Interpreter
      _interpreter = await Interpreter.fromAsset('assets/models/sign_language/isl_model.tflite');
      _isModelLoaded = true;

      debugPrint('[ISL_ML] Successfully loaded TFLite model: assets/models/sign_language/isl_model.tflite');
      debugPrint('[ISL_ML] Model class labels count: ${_labels.length}');
      debugPrint('[ISL_ML] Input shape: ${_interpreter?.getInputTensor(0).shape}, Output shape: ${_interpreter?.getOutputTensor(0).shape}');
      return true;
    } catch (e) {
      debugPrint('[ISL_ML] TFLite model initialization fallback/note: $e');
      _isModelLoaded = false;
      return false;
    }
  }

  /// Extracts 20-D body and hand-invariant feature vector matching training pipeline:
  /// Hand Shape (12 values):
  ///   [0]: idx_dx, [1]: idx_dy, [2]: idx_dist
  ///   [3]: thm_dx, [4]: thm_dy, [5]: thm_dist
  ///   [6]: pnk_dx, [7]: pnk_dy, [8]: pnk_dist
  ///   [9]: dist_ti, [10]: dist_ip, [11]: dist_tp
  /// Spatial Pose (8 values):
  ///   [12]: rw_x, [13]: rw_y, [14]: rw_z
  ///   [15]: lw_x, [16]: lw_y
  ///   [17]: rwn_y, [18]: re_x, [19]: re_y
  List<double>? extract20DFeatures(Pose pose) {
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightIndex = pose.landmarks[PoseLandmarkType.rightIndex];
    final rightThumb = pose.landmarks[PoseLandmarkType.rightThumb];
    final rightPinky = pose.landmarks[PoseLandmarkType.rightPinky];
    final leftIndex = pose.landmarks[PoseLandmarkType.leftIndex];
    final leftThumb = pose.landmarks[PoseLandmarkType.leftThumb];
    final leftPinky = pose.landmarks[PoseLandmarkType.leftPinky];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    // Must have at least one active hand wrist
    if (rightWrist == null && leftWrist == null) {
      return null;
    }

    // Determine dominant/signing hand (prefer right hand, or left if right is absent or left is higher)
    final bool useRightHand = rightWrist != null &&
        (leftWrist == null || (rightWrist.y <= leftWrist.y));

    final wrist = useRightHand ? rightWrist! : leftWrist!;
    final index = useRightHand ? (rightIndex ?? wrist) : (leftIndex ?? wrist);
    final thumb = useRightHand ? (rightThumb ?? wrist) : (leftThumb ?? wrist);
    final pinky = useRightHand ? (rightPinky ?? wrist) : (leftPinky ?? wrist);

    double dist(PoseLandmark a, PoseLandmark b) {
      final dx = a.x - b.x;
      final dy = a.y - b.y;
      return math.sqrt(dx * dx + dy * dy);
    }

    final double dIndex = dist(index, wrist);
    final double dThumb = dist(thumb, wrist);
    final double dPinky = dist(pinky, wrist);

    // Hand scale normalization
    final double handScale = math.max(0.05, math.max(dIndex, math.max(dThumb, dPinky)));

    final double idxDx = (index.x - wrist.x) / handScale;
    final double idxDy = (index.y - wrist.y) / handScale;
    final double idxDist = dIndex / handScale;

    final double thmDx = (thumb.x - wrist.x) / handScale;
    final double thmDy = (thumb.y - wrist.y) / handScale;
    final double thmDist = dThumb / handScale;

    final double pnkDx = (pinky.x - wrist.x) / handScale;
    final double pnkDy = (pinky.y - wrist.y) / handScale;
    final double pnkDist = dPinky / handScale;

    final double distTI = dist(thumb, index) / handScale;
    final double distIP = dist(index, pinky) / handScale;
    final double distTP = dist(thumb, pinky) / handScale;

    // Body & spatial arm features
    double rwX = 0.15;
    double rwY = 0.30;
    double rwZ = 0.0;
    double lwX = -0.20;
    double lwY = 0.30;
    double rwnY = 0.50;
    double reX = 0.25;
    double reY = 0.10;

    if (rightShoulder != null && leftShoulder != null) {
      final double centerX = (rightShoulder.x + leftShoulder.x) / 2.0;
      final double centerY = (rightShoulder.y + leftShoulder.y) / 2.0;
      final double dx = rightShoulder.x - leftShoulder.x;
      final double dy = rightShoulder.y - leftShoulder.y;
      final double shoulderSpan = math.max(1.0, math.sqrt(dx * dx + dy * dy));

      if (rightWrist != null) {
        rwX = (rightWrist.x - centerX) / shoulderSpan;
        rwY = (rightWrist.y - centerY) / shoulderSpan;
        rwZ = (rightWrist.z) / shoulderSpan;
      }
      if (leftWrist != null) {
        lwX = (leftWrist.x - centerX) / shoulderSpan;
        lwY = (leftWrist.y - centerY) / shoulderSpan;
      }
      final double headY = nose != null ? nose.y : (centerY - shoulderSpan * 0.5);
      if (rightWrist != null) {
        rwnY = (rightWrist.y - headY) / shoulderSpan;
      }
      if (rightElbow != null) {
        reX = (rightElbow.x - centerX) / shoulderSpan;
        reY = (rightElbow.y - centerY) / shoulderSpan;
      }
    }

    return [
      idxDx, idxDy, idxDist,
      thmDx, thmDy, thmDist,
      pnkDx, pnkDy, pnkDist,
      distTI, distIP, distTP,
      rwX, rwY, rwZ,
      lwX, lwY,
      rwnY, reX, reY,
    ];
  }

  /// Extracts 14-D features (legacy wrapper redirecting to 20D for pipeline compatibility)
  List<double>? extract14DFeatures(Pose pose) => extract20DFeatures(pose);

  /// Run TFLite neural inference and return softmax probability distribution across classes
  List<double> inferProbabilities(List<double> features) {
    if (_interpreter == null || !_isModelLoaded) {
      return List<double>.filled(_labels.isNotEmpty ? _labels.length : 6, 0.0);
    }

    final int numClasses = _labels.isNotEmpty ? _labels.length : 6;
    final input = [features]; // Shape: [1, 20]
    final output = List<double>.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

    _interpreter!.run(input, output);

    final List<double> logits = List<double>.from(output[0]);
    final double maxLogit = logits.reduce(math.max);
    final List<double> exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final double sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  /// Direct inference from feature vector (for unit testing and verification)
  RecognizedSignResult? inferFromFeatures(List<double> features) {
    List<double> inputFeats = features;
    if (features.length == 14) {
      inputFeats = List<double>.from(features)..addAll(List<double>.filled(6, 0.0));
    }
    if (inputFeats.length != 20) return null;

    final probs = inferProbabilities(inputFeats);
    if (probs.isEmpty) return null;

    int maxIdx = 0;
    double maxProb = 0.0;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIdx = i;
      }
    }

    if (maxProb < confidenceThreshold || maxIdx >= _labels.length) {
      return null;
    }

    final phraseId = _labels[maxIdx];
    final phraseEntry = SignLanguagePhraseRegistry.phrases.firstWhere(
      (p) => p.id == phraseId,
      orElse: () => SignLanguagePhraseRegistry.phrases.first,
    );

    return RecognizedSignResult(
      signName: phraseEntry.displayText,
      phraseId: phraseId,
      confidence: maxProb,
      category: phraseId.length == 1 ? 'Alphabet' : 'Phrase',
      timestamp: DateTime.now(),
    );

  }

  /// Detailed sequence recognition with comprehensive diagnostic logging
  Future<DetailedSignRecognitionResult> processSequenceDetailed(List<InputImage> frames) async {
    final int totalFrames = frames.length;
    if (totalFrames == 0) {
      debugPrint('[ISL_DIAGNOSTIC] Frame count: 0. Rejection reason: Empty sequence.');
      return const DetailedSignRecognitionResult(
        status: SequenceRecognitionStatus.noFrames,
        totalFrames: 0,
        validFrames: 0,
        message: 'No frames captured. Please record a gesture.',
      );
    }

    if (!_isModelLoaded) {
      await initializeModel();
    }

    if (_interpreter == null || !_isModelLoaded) {
      debugPrint('[ISL_DIAGNOSTIC] Rejection reason: Interpreter unavailable.');
      return const DetailedSignRecognitionResult(
        status: SequenceRecognitionStatus.error,
        totalFrames: 0,
        validFrames: 0,
        message: 'ISL Model interpreter unavailable.',
      );
    }

    final List<List<double>> sequenceProbs = [];
    int validPoses = 0;

    for (final frame in frames) {
      try {
        final poses = await _poseDetector.processImage(frame);
        if (poses.isEmpty) continue;
        final features = extract14DFeatures(poses.first);
        if (features == null) continue;

        validPoses++;
        final probs = inferProbabilities(features);
        sequenceProbs.add(probs);
      } catch (e) {
        debugPrint('[ISL_DIAGNOSTIC] Frame pose processing exception: $e');
      }
    }

    debugPrint('[ISL_DIAGNOSTIC] Landmark detection count: $validPoses / $totalFrames frames with valid body landmarks.');
    debugPrint('[ISL_DIAGNOSTIC] Model input shape: ${_interpreter?.getInputTensor(0).shape}');
    debugPrint('[ISL_DIAGNOSTIC] Model output shape: ${_interpreter?.getOutputTensor(0).shape}');

    if (sequenceProbs.isEmpty) {
      debugPrint('[ISL_DIAGNOSTIC] Rejection reason: No body or hand landmarks detected across sequence.');
      return DetailedSignRecognitionResult(
        status: SequenceRecognitionStatus.noLandmarksDetected,
        totalFrames: totalFrames,
        validFrames: 0,
        message: 'Hands or body not detected. Ensure your upper body, arms, and hands are visible in frame.',
      );
    }

    // Mean pooling across sequence frames
    final int numClasses = _labels.length;
    final List<double> meanProbs = List<double>.filled(numClasses, 0.0);
    for (final probs in sequenceProbs) {
      for (int i = 0; i < numClasses && i < probs.length; i++) {
        meanProbs[i] += probs[i];
      }
    }
    for (int i = 0; i < numClasses; i++) {
      meanProbs[i] /= sequenceProbs.length;
    }

    int bestIdx = 0;
    double bestConfidence = 0.0;
    for (int i = 0; i < meanProbs.length; i++) {
      if (meanProbs[i] > bestConfidence) {
        bestConfidence = meanProbs[i];
        bestIdx = i;
      }
    }

    final String topLabel = bestIdx < _labels.length ? _labels[bestIdx] : 'unknown';
    debugPrint('[ISL_DIAGNOSTIC] Top prediction: class $bestIdx ($topLabel) with confidence ${(bestConfidence * 100).toStringAsFixed(1)}%. Confidence threshold: ${(confidenceThreshold * 100).toStringAsFixed(1)}%.');

    if (bestConfidence < confidenceThreshold) {
      debugPrint('[ISL_DIAGNOSTIC] Rejection reason: Top confidence (${(bestConfidence * 100).toStringAsFixed(1)}%) is below threshold (${(confidenceThreshold * 100).toStringAsFixed(1)}%).');
      return DetailedSignRecognitionResult(
        status: SequenceRecognitionStatus.lowConfidence,
        totalFrames: totalFrames,
        validFrames: validPoses,
        topCandidate: topLabel,
        topCandidateConfidence: bestConfidence,
        message: 'Sign not recognized. Please try again.',
      );
    }

    final phraseId = _labels[bestIdx];
    final phraseEntry = SignLanguagePhraseRegistry.phrases.firstWhere(
      (p) => p.id == phraseId,
      orElse: () => SignLanguagePhraseRegistry.phrases.first,
    );

    final signResult = RecognizedSignResult(
      signName: phraseEntry.displayText,
      phraseId: phraseId,
      confidence: bestConfidence,
      category: 'Phrase',
      timestamp: DateTime.now(),
    );

    debugPrint('[ISL_DIAGNOSTIC] Recognition ACCEPTED: ${phraseEntry.displayText} (${(bestConfidence * 100).toStringAsFixed(1)}%)');

    return DetailedSignRecognitionResult(
      status: SequenceRecognitionStatus.success,
      result: signResult,
      signName: phraseEntry.displayText,
      phraseId: phraseId,
      confidence: bestConfidence,
      totalFrames: totalFrames,
      validFrames: validPoses,
      topCandidate: topLabel,
      topCandidateConfidence: bestConfidence,
      message: 'Recognized: ${phraseEntry.displayText}',
    );
  }

  /// Analyzes a recorded sequence of frames captured during signing
  Future<RecognizedSignResult?> processSequence(List<InputImage> frames) async {
    final detailed = await processSequenceDetailed(frames);
    return detailed.result;
  }

  /// Process individual camera frame (for live streaming / real-time testing)
  Future<RecognizedSignResult?> processCameraFrame(InputImage inputImage) async {
    try {
      if (!_isModelLoaded) {
        await initializeModel();
      }

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) return null;

      final features = extract14DFeatures(poses.first);
      if (features == null) return null;

      final probs = inferProbabilities(features);
      if (probs.isEmpty) return null;

      int maxIdx = 0;
      double maxProb = 0.0;
      for (int i = 0; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          maxIdx = i;
        }
      }

      final confidence = maxProb;
      final predictedPhraseId = maxIdx < _labels.length ? _labels[maxIdx] : 'hello';

      // Temporal Consensus Smoothing (last 5 frames)
      _predictionHistory.add(predictedPhraseId);
      if (_predictionHistory.length > 5) {
        _predictionHistory.removeAt(0);
      }

      final frequencyMap = <String, int>{};
      for (final id in _predictionHistory) {
        frequencyMap[id] = (frequencyMap[id] ?? 0) + 1;
      }

      String consensusId = predictedPhraseId;
      int maxCount = 0;
      frequencyMap.forEach((id, count) {
        if (count > maxCount) {
          maxCount = count;
          consensusId = id;
        }
      });

      if (maxCount < 2 || confidence < confidenceThreshold) {
        return null;
      }

      final now = DateTime.now();
      if (_lastEmittedSign == consensusId &&
          _lastEmittedTime != null &&
          now.difference(_lastEmittedTime!) < const Duration(milliseconds: 2000)) {
        return null;
      }

      _lastEmittedSign = consensusId;
      _lastEmittedTime = now;

      final phraseEntry = SignLanguagePhraseRegistry.phrases.firstWhere(
        (p) => p.id == consensusId,
        orElse: () => SignLanguagePhraseRegistry.phrases.first,
      );

      return RecognizedSignResult(
        signName: phraseEntry.displayText,
        phraseId: phraseEntry.id,
        confidence: confidence,
        category: 'Phrase',
        timestamp: now,
      );
    } catch (e) {
      debugPrint('[ISL_ML] Frame processing error: $e');
      return null;
    }
  }

  void resetTemporalBuffer() {
    _predictionHistory.clear();
    _lastEmittedSign = null;
    _lastEmittedTime = null;
  }

  Future<void> dispose() async {
    try {
      _interpreter?.close();
      await _poseDetector.close();
    } catch (_) {}
  }
}
