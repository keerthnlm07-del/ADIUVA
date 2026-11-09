import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Spatial direction derived ONLY from verified spatial coordinates (e.g. YOLO bounding boxes)
enum SpatialDirection {
  unspecified,
  ahead,
  left,
  right,
}

/// Single Class Confidence Candidate
class ClassConfidence {
  final String label;
  final String displayName;
  final double confidence;

  const ClassConfidence({
    required this.label,
    required this.displayName,
    required this.confidence,
  });

  int get confidencePercent => (confidence * 100).round();

  @override
  String toString() => displayName;
}

/// Comprehensive Object Classification Result
class ObjectClassificationResult {
  final String label;
  final String displayName;
  final double confidence;
  final List<ClassConfidence> topAlternatives;
  final int inferenceTimeMs;

  const ObjectClassificationResult({
    required this.label,
    required this.displayName,
    required this.confidence,
    required this.topAlternatives,
    required this.inferenceTimeMs,
  });

  int get confidencePercent => (confidence * 100).round();

  /// Natural accessibility speech output without confidence percentages
  String toNaturalSpeech({SpatialDirection direction = SpatialDirection.unspecified}) {
    return AdiuvaObjectClassifierService.formatNaturalPhrase(
      label,
      displayName,
      direction: direction,
    );
  }

  /// Backward-compatible alias returning natural concise speech without percentages
  String toAccessibleSpokenText({SpatialDirection direction = SpatialDirection.unspecified}) {
    return toNaturalSpeech(direction: direction);
  }
}

/// On-Device Assistive Object Classifier Service using MobileNetV3-Small
/// Trained on 19 assistive object categories from the ADIUVA dataset:
/// Book, Bottle, Chair, Chalk, Charger, Cup, Earphone Case, Keyboard, Keys,
/// Laptop, Mobile Phone, Mouse, Paper, Pen, Pencil, Person, Table, Wallet, Watch.
class AdiuvaObjectClassifierService {
  static const String modelAssetPath = 'assets/models/visual_assistance/adiuva_object_classifier.tflite';
  static const String labelsAssetPath = 'assets/models/visual_assistance/labels.txt';

  static const int inputWidth = 224;
  static const int inputHeight = 224;
  static const int inputChannels = 3;

  // ImageNet normalization constants used during PyTorch fine-tuning
  static const List<double> normMean = [0.485, 0.456, 0.406];
  static const List<double> normStd = [0.229, 0.224, 0.225];

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitializing = false;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<String> get labels => List.unmodifiable(_labels);

  AdiuvaObjectClassifierService({Interpreter? interpreter, List<String>? labels}) {
    if (interpreter != null) {
      _interpreter = interpreter;
      _isInitialized = true;
    }
    if (labels != null) {
      _labels = List.from(labels);
    } else {
      _initDefaultLabels();
    }
  }

  /// Default 19-class label list from dataset
  void _initDefaultLabels() {
    _labels = const [
      'book',
      'bottle',
      'chair',
      'chalk',
      'charger',
      'cup',
      'earphone_case',
      'keyboard',
      'keys',
      'laptop',
      'mobile_phone',
      'mouse',
      'paper',
      'pen',
      'pencil',
      'person',
      'table',
      'wallet',
      'watch',
    ];
  }

  /// Initialize the TFLite Interpreter and load labels from assets
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      final stopwatch = Stopwatch()..start();
      debugPrint('[ADIUVA_CLASSIFIER] Loading on-device model from $modelAssetPath...');

      // Load labels from asset file if available
      try {
        final labelsData = await rootBundle.loadString(labelsAssetPath);
        final loaded = labelsData
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        if (loaded.isNotEmpty) {
          _labels = loaded;
        }
      } catch (e) {
        debugPrint('[ADIUVA_CLASSIFIER] Note: Using default label map ($e)');
      }

      // Configure multi-threaded inference
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);

      stopwatch.stop();
      _isInitialized = true;
      debugPrint('[ADIUVA_CLASSIFIER] Model loaded in ${stopwatch.elapsedMilliseconds} ms with ${_labels.length} classes.');
    } catch (e, stackTrace) {
      debugPrint('[ADIUVA_CLASSIFIER] Initialization error: $e');
      debugPrint('[ADIUVA_CLASSIFIER] StackTrace: $stackTrace');
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Format machine label into user-friendly display name
  static String formatDisplayName(String label) {
    switch (label) {
      case 'book':
        return 'Book';
      case 'bottle':
        return 'Bottle';
      case 'chair':
        return 'Chair';
      case 'chalk':
        return 'Chalk';
      case 'charger':
        return 'Charger';
      case 'cup':
        return 'Cup';
      case 'earphone_case':
        return 'Earphone Case';
      case 'keyboard':
        return 'Keyboard';
      case 'keys':
        return 'Keys';
      case 'laptop':
        return 'Laptop';
      case 'mobile_phone':
        return 'Mobile Phone';
      case 'mouse':
        return 'Mouse';
      case 'paper':
        return 'Paper';
      case 'pen':
        return 'Pen';
      case 'pencil':
        return 'Pencil';
      case 'person':
        return 'Person';
      case 'table':
        return 'Table';
      case 'wallet':
        return 'Wallet';
      case 'watch':
        return 'Watch';
      default:
        return label
            .split('_')
            .map((part) => part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  /// Format multi-object spatial relationship (e.g. 'I can see a bottle beside a laptop.')
  static String formatRelationshipPhrase(
    String labelA,
    String labelB, {
    String relation = 'beside',
  }) {
    final nameA = formatDisplayName(labelA).toLowerCase().trim();
    final nameB = formatDisplayName(labelB).toLowerCase().trim();
    final articleA = ['a', 'e', 'i', 'o', 'u'].contains(nameA.isNotEmpty ? nameA[0] : 'a') ? 'an' : 'a';
    final articleB = ['a', 'e', 'i', 'o', 'u'].contains(nameB.isNotEmpty ? nameB[0] : 'a') ? 'an' : 'a';
    return 'I can see $articleA $nameA $relation $articleB $nameB.';
  }

  /// Format natural spoken sentence for visually impaired users without percentages.
  /// Direction is included only when backed by a verified spatial source (e.g. YOLO bounding box).
  static String formatNaturalPhrase(
    String label,
    String displayName, {
    SpatialDirection direction = SpatialDirection.unspecified,
  }) {
    final cleanLabel = label.toLowerCase().trim().replaceAll(' ', '_');

    switch (cleanLabel) {
      case 'person':
        switch (direction) {
          case SpatialDirection.left:
            return 'A person is on your left.';
          case SpatialDirection.right:
            return 'A person is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A person is standing in front of you.';
        }

      case 'chair':
        switch (direction) {
          case SpatialDirection.left:
            return 'There is a chair to your left.';
          case SpatialDirection.right:
            return 'There is a chair to your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'There is a chair ahead of you.';
        }

      case 'bottle':
        switch (direction) {
          case SpatialDirection.left:
            return 'A bottle is on your left.';
          case SpatialDirection.right:
            return 'A bottle is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A bottle is visible in front of you.';
        }

      case 'table':
        switch (direction) {
          case SpatialDirection.left:
            return 'There is a table to your left.';
          case SpatialDirection.right:
            return 'There is a table to your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'There is a table ahead of you.';
        }

      case 'cup':
        switch (direction) {
          case SpatialDirection.left:
            return 'A cup is on your left.';
          case SpatialDirection.right:
            return 'A cup is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A cup is visible in front of you.';
        }

      case 'book':
        switch (direction) {
          case SpatialDirection.left:
            return 'A book is on your left.';
          case SpatialDirection.right:
            return 'A book is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A book is in front of you.';
        }

      case 'chalk':
        switch (direction) {
          case SpatialDirection.left:
            return 'Chalk is on your left.';
          case SpatialDirection.right:
            return 'Chalk is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'Chalk is visible in front of you.';
        }

      case 'charger':
        switch (direction) {
          case SpatialDirection.left:
            return 'A charger is on your left.';
          case SpatialDirection.right:
            return 'A charger is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A charger is in front of you.';
        }

      case 'earphone_case':
        switch (direction) {
          case SpatialDirection.left:
            return 'An earphone case is on your left.';
          case SpatialDirection.right:
            return 'An earphone case is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'An earphone case is in front of you.';
        }

      case 'keyboard':
        switch (direction) {
          case SpatialDirection.left:
            return 'A keyboard is on your left.';
          case SpatialDirection.right:
            return 'A keyboard is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A keyboard is in front of you.';
        }

      case 'keys':
        switch (direction) {
          case SpatialDirection.left:
            return 'Keys are on your left.';
          case SpatialDirection.right:
            return 'Keys are on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'Keys are visible in front of you.';
        }

      case 'laptop':
        switch (direction) {
          case SpatialDirection.left:
            return 'A laptop is on your left.';
          case SpatialDirection.right:
            return 'A laptop is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A laptop is in front of you.';
        }

      case 'mobile_phone':
        switch (direction) {
          case SpatialDirection.left:
            return 'A mobile phone is on your left.';
          case SpatialDirection.right:
            return 'A mobile phone is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A mobile phone is in front of you.';
        }

      case 'mouse':
        switch (direction) {
          case SpatialDirection.left:
            return 'A computer mouse is on your left.';
          case SpatialDirection.right:
            return 'A computer mouse is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A computer mouse is in front of you.';
        }

      case 'paper':
        switch (direction) {
          case SpatialDirection.left:
            return 'Paper is on your left.';
          case SpatialDirection.right:
            return 'Paper is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'Paper is visible in front of you.';
        }

      case 'pen':
        switch (direction) {
          case SpatialDirection.left:
            return 'A pen is on your left.';
          case SpatialDirection.right:
            return 'A pen is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A pen is visible in front of you.';
        }

      case 'pencil':
        switch (direction) {
          case SpatialDirection.left:
            return 'A pencil is on your left.';
          case SpatialDirection.right:
            return 'A pencil is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A pencil is visible in front of you.';
        }

      case 'wallet':
        switch (direction) {
          case SpatialDirection.left:
            return 'A wallet is on your left.';
          case SpatialDirection.right:
            return 'A wallet is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A wallet is visible in front of you.';
        }

      case 'watch':
        switch (direction) {
          case SpatialDirection.left:
            return 'A watch is on your left.';
          case SpatialDirection.right:
            return 'A watch is on your right.';
          case SpatialDirection.ahead:
          case SpatialDirection.unspecified:
            return 'A watch is visible in front of you.';
        }

      default:
        final name = displayName.toLowerCase().trim();
        if (name.isEmpty) {
          switch (direction) {
            case SpatialDirection.left:
              return 'An object is on your left.';
            case SpatialDirection.right:
              return 'An object is on your right.';
            case SpatialDirection.ahead:
            case SpatialDirection.unspecified:
              return 'An object is visible in front of you.';
          }
        }
        final firstChar = name[0];
        final article = ['a', 'e', 'i', 'o', 'u'].contains(firstChar) ? 'an' : 'a';
        switch (direction) {
          case SpatialDirection.left:
            return '$article $name is on your left.';
          case SpatialDirection.right:
            return '$article $name is on your right.';
          case SpatialDirection.ahead:
            return 'There is $article $name ahead of you.';
          case SpatialDirection.unspecified:
            return '$article $name is visible in front of you.';
        }
    }
  }

  /// Classify an image file on device storage
  Future<ObjectClassificationResult?> classifyImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[ADIUVA_CLASSIFIER] File does not exist at: $imagePath');
        return null;
      }

      final Uint8List bytes = await file.readAsBytes();
      return await classifyBytes(bytes);
    } catch (e) {
      debugPrint('[ADIUVA_CLASSIFIER] Error reading file: $e');
      return null;
    }
  }

  /// Classify raw image bytes
  Future<ObjectClassificationResult?> classifyBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized || _interpreter == null) {
        debugPrint('[ADIUVA_CLASSIFIER] Interpreter unavailable.');
        return null;
      }
    }

    final stopwatch = Stopwatch()..start();

    try {
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('[ADIUVA_CLASSIFIER] Failed to decode image bytes.');
        return null;
      }

      // Resize image to 224x224 (linear interpolation)
      final resizedImage = img.copyResize(
        decodedImage,
        width: inputWidth,
        height: inputHeight,
        interpolation: img.Interpolation.linear,
      );

      // Preprocess image buffer with ImageNet standardization [1, 224, 224, 3]
      final Float32List inputBuffer = Float32List(1 * inputWidth * inputHeight * inputChannels);
      int pixelIndex = 0;

      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = resizedImage.getPixel(x, y);

          // Standardize: (channel / 255.0 - mean) / std
          final double rNorm = ((pixel.r / 255.0) - normMean[0]) / normStd[0];
          final double gNorm = ((pixel.g / 255.0) - normMean[1]) / normStd[1];
          final double bNorm = ((pixel.b / 255.0) - normMean[2]) / normStd[2];

          inputBuffer[pixelIndex++] = rNorm;
          inputBuffer[pixelIndex++] = gNorm;
          inputBuffer[pixelIndex++] = bNorm;
        }
      }

      return _runInferenceOnBuffer(inputBuffer, stopwatch);
    } catch (e, stackTrace) {
      debugPrint('[ADIUVA_CLASSIFIER] Inference error: $e');
      debugPrint('[ADIUVA_CLASSIFIER] StackTrace: $stackTrace');
      return null;
    }
  }

  /// Classify a live camera frame directly from CameraImage
  Future<ObjectClassificationResult?> classifyCameraImage(
    CameraImage image, {
    int rotation = 90,
  }) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized || _interpreter == null) {
        return null;
      }
    }

    if (image.planes.isEmpty) return null;

    final stopwatch = Stopwatch()..start();

    try {
      final Float32List inputBuffer = Float32List(1 * inputWidth * inputHeight * inputChannels);

      final bool isYuv = image.format.group == ImageFormatGroup.yuv420 && image.planes.length >= 3;

      if (isYuv) {
        _convertYuvToNormalizedFloat32(image, inputBuffer, rotation);
      } else if (image.planes.length == 1) {
        _convertSinglePlaneToNormalizedFloat32(image, inputBuffer, rotation);
      } else {
        _convertLumaToNormalizedFloat32(image, inputBuffer, rotation);
      }

      return _runInferenceOnBuffer(inputBuffer, stopwatch);
    } catch (e) {
      debugPrint('[ADIUVA_CLASSIFIER] Live camera inference error: $e');
      return null;
    }
  }

  void _convertYuvToNormalizedFloat32(
    CameraImage image,
    Float32List inputBuffer,
    int rotation,
  ) {
    final int srcW = image.width;
    final int srcH = image.height;
    final int visualW = (rotation == 90 || rotation == 270) ? srcH : srcW;
    final int visualH = (rotation == 90 || rotation == 270) ? srcW : srcH;

    final int yRowStride = image.planes[0].bytesPerRow;
    final int yPixelStride = image.planes[0].bytesPerPixel ?? 1;

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final Uint8List yBuffer = image.planes[0].bytes;
    final Uint8List uBuffer = image.planes[1].bytes;
    final Uint8List vBuffer = image.planes[2].bytes;
    final int uBufferLen = uBuffer.length;
    final int vBufferLen = vBuffer.length;
    final int yBufferLen = yBuffer.length;

    // Center crop coordinates in visual frame
    final int cropSize = math.min(visualW, visualH);
    final int cropX0 = (visualW - cropSize) ~/ 2;
    final int cropY0 = (visualH - cropSize) ~/ 2;

    int pixelIndex = 0;

    for (int y = 0; y < inputHeight; y++) {
      final int uY = cropY0 + ((y * cropSize) ~/ inputHeight);
      for (int x = 0; x < inputWidth; x++) {
        final int uX = cropX0 + ((x * cropSize) ~/ inputWidth);

        int srcX;
        int srcY;

        if (rotation == 90) {
          srcX = (visualH - 1 - uY).clamp(0, srcW - 1);
          srcY = uX.clamp(0, srcH - 1);
        } else if (rotation == 270) {
          srcX = uY.clamp(0, srcW - 1);
          srcY = (visualW - 1 - uX).clamp(0, srcH - 1);
        } else {
          srcX = uX.clamp(0, srcW - 1);
          srcY = uY.clamp(0, srcH - 1);
        }

        final int yIndex = (srcY * yRowStride + srcX * yPixelStride).clamp(0, yBufferLen - 1);
        final int uvIndex = ((srcY >> 1) * uvRowStride + (srcX >> 1) * uvPixelStride);
        final int uIdx = uvIndex.clamp(0, uBufferLen - 1);
        final int vIdx = uvIndex.clamp(0, vBufferLen - 1);

        final int yVal = yBuffer[yIndex] & 0xFF;
        final int uVal = (uBuffer[uIdx] & 0xFF) - 128;
        final int vVal = (vBuffer[vIdx] & 0xFF) - 128;

        final double r = (yVal + 1.370705 * vVal).clamp(0, 255) / 255.0;
        final double g = (yVal - 0.337633 * uVal - 0.698001 * vVal).clamp(0, 255) / 255.0;
        final double b = (yVal + 1.732446 * uVal).clamp(0, 255) / 255.0;

        // ImageNet normalization: (channel - mean) / std
        inputBuffer[pixelIndex++] = (r - normMean[0]) / normStd[0];
        inputBuffer[pixelIndex++] = (g - normMean[1]) / normStd[1];
        inputBuffer[pixelIndex++] = (b - normMean[2]) / normStd[2];
      }
    }
  }

  void _convertSinglePlaneToNormalizedFloat32(
    CameraImage image,
    Float32List inputBuffer,
    int rotation,
  ) {
    final plane = image.planes[0];
    final bytes = plane.bytes;
    final int rowStride = plane.bytesPerRow;
    final int pixelStride = plane.bytesPerPixel ?? 4;
    final int srcW = image.width;
    final int srcH = image.height;
    final int visualW = (rotation == 90 || rotation == 270) ? srcH : srcW;
    final int visualH = (rotation == 90 || rotation == 270) ? srcW : srcH;

    final int cropSize = math.min(visualW, visualH);
    final int cropX0 = (visualW - cropSize) ~/ 2;
    final int cropY0 = (visualH - cropSize) ~/ 2;

    int pixelIndex = 0;

    for (int y = 0; y < inputHeight; y++) {
      final int uY = cropY0 + ((y * cropSize) ~/ inputHeight);
      for (int x = 0; x < inputWidth; x++) {
        final int uX = cropX0 + ((x * cropSize) ~/ inputWidth);

        int srcX;
        int srcY;
        if (rotation == 90) {
          srcX = (visualH - 1 - uY).clamp(0, srcW - 1);
          srcY = uX.clamp(0, srcH - 1);
        } else if (rotation == 270) {
          srcX = uY.clamp(0, srcW - 1);
          srcY = (visualW - 1 - uX).clamp(0, srcH - 1);
        } else {
          srcX = uX.clamp(0, srcW - 1);
          srcY = uY.clamp(0, srcH - 1);
        }

        final int byteIdx = (srcY * rowStride + srcX * pixelStride);
        double r = 0.0;
        double g = 0.0;
        double b = 0.0;

        if (byteIdx + 2 < bytes.length) {
          b = bytes[byteIdx] / 255.0;
          g = bytes[byteIdx + 1] / 255.0;
          r = bytes[byteIdx + 2] / 255.0;
        }

        inputBuffer[pixelIndex++] = (r - normMean[0]) / normStd[0];
        inputBuffer[pixelIndex++] = (g - normMean[1]) / normStd[1];
        inputBuffer[pixelIndex++] = (b - normMean[2]) / normStd[2];
      }
    }
  }

  void _convertLumaToNormalizedFloat32(
    CameraImage image,
    Float32List inputBuffer,
    int rotation,
  ) {
    final plane = image.planes[0];
    final bytes = plane.bytes;
    final int srcW = image.width;
    final int srcH = image.height;
    int pixelIndex = 0;

    for (int y = 0; y < inputHeight; y++) {
      final int srcY = ((y * srcH) ~/ inputHeight).clamp(0, srcH - 1);
      for (int x = 0; x < inputWidth; x++) {
        final int srcX = ((x * srcW) ~/ inputWidth).clamp(0, srcW - 1);
        final int idx = (srcY * plane.bytesPerRow + srcX * (plane.bytesPerPixel ?? 1)).clamp(0, bytes.length - 1);
        final double luma = (bytes[idx] & 0xFF) / 255.0;
        inputBuffer[pixelIndex++] = (luma - normMean[0]) / normStd[0];
        inputBuffer[pixelIndex++] = (luma - normMean[1]) / normStd[1];
        inputBuffer[pixelIndex++] = (luma - normMean[2]) / normStd[2];
      }
    }
  }

  ObjectClassificationResult _runInferenceOnBuffer(Float32List inputBuffer, Stopwatch stopwatch) {
    final input = inputBuffer.reshape([1, inputWidth, inputHeight, inputChannels]);
    final int numClasses = _labels.length;
    final output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

    _interpreter!.run(input, output);

    final List<dynamic> rawLogits = output[0] as List<dynamic>;
    final List<double> logits = rawLogits.map((e) => (e as num).toDouble()).toList();

    // Softmax computation
    final double maxLogit = logits.reduce(math.max);
    final List<double> expScores = logits.map((z) => math.exp(z - maxLogit)).toList();
    final double sumExp = expScores.reduce((a, b) => a + b);
    final List<double> probabilities = expScores.map((exp) => exp / sumExp).toList();

    // Rank top candidates
    final List<int> sortedIndices = List<int>.generate(probabilities.length, (i) => i)
      ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));

    final List<ClassConfidence> topAlternatives = sortedIndices.take(3).map((idx) {
      final label = idx < _labels.length ? _labels[idx] : 'class_$idx';
      return ClassConfidence(
        label: label,
        displayName: formatDisplayName(label),
        confidence: probabilities[idx],
      );
    }).toList();

    stopwatch.stop();

    final topResult = topAlternatives.isNotEmpty
        ? topAlternatives.first
        : ClassConfidence(label: 'unknown', displayName: 'Unknown', confidence: 0.0);

    return ObjectClassificationResult(
      label: topResult.label,
      displayName: topResult.displayName,
      confidence: topResult.confidence,
      topAlternatives: topAlternatives,
      inferenceTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Close interpreter and release native resources
  void close() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
