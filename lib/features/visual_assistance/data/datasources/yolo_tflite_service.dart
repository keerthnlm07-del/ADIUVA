import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Detected Object Bounding Box Entity
class DetectedObjectBox {
  final String label;
  final double confidence;
  final double left;
  final double top;
  final double right;
  final double bottom;

  DetectedObjectBox({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

class _LetterboxParams {
  final double scale;
  final double padX;
  final double padY;
  final double wScaled;
  final double hScaled;

  _LetterboxParams({
    required this.scale,
    required this.padX,
    required this.padY,
    required this.wScaled,
    required this.hScaled,
  });
}

/// Real On-Device Object Detection Service using Genuine YOLOv8n TensorFlow Lite Model
class YoloTfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitializing = false;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // High-priority accessibility vocabulary (80 COCO classes supported)
  static const List<String> supportedClasses = [
    'person', 'cell phone', 'laptop', 'bottle', 'cup', 'chair',
    'table', 'dining table', 'backpack', 'book', 'mouse', 'keyboard',
    'car', 'bicycle', 'bus', 'traffic light', 'stop sign', 'tv', 'couch'
  ];

  YoloTfliteService() {
    _initDetector();
  }

  Future<void> _initDetector() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      final stopwatch = Stopwatch()..start();
      debugPrint('[GENUINE YOLOv8] Initializing on-device YOLOv8n model...');

      // Load labels from assets
      final labelsData = await rootBundle.loadString('assets/models/yolo/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      debugPrint('[GENUINE YOLOv8] Loaded ${_labels.length} COCO object labels.');

      final options = InterpreterOptions()..threads = 4;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/yolo/yolov8n.tflite',
        options: options,
      );

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      stopwatch.stop();
      _isInitialized = true;
      debugPrint('[GENUINE YOLOv8] YOLOv8n TFLite model loaded successfully in ${stopwatch.elapsedMilliseconds} ms!');
      debugPrint('[GENUINE YOLOv8] Input Tensor: Name ${inputTensor.name}, Shape ${inputTensor.shape}, Type ${inputTensor.type}');
      debugPrint('[GENUINE YOLOv8] Output Tensor: Name ${outputTensor.name}, Shape ${outputTensor.shape}, Type ${outputTensor.type}');
    } catch (e, stackTrace) {
      debugPrint('[GENUINE YOLOv8] Model initialization error: $e');
      debugPrint('[GENUINE YOLOv8] StackTrace: $stackTrace');
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Execute real on-device YOLOv8 inference on live CameraImage stream (Zero disk I/O)
  Future<List<DetectedObjectBox>> detectObjectsFromCameraImage(
    CameraImage image, {
    int rotation = 90,
  }) async {
    if (!_isInitialized) {
      await _initDetector();
      if (!_isInitialized || _interpreter == null) return [];
    }

    try {
      final inputTensor = _interpreter!.getInputTensor(0);
      final int inputWidth = inputTensor.shape.length > 2 ? inputTensor.shape[1] : 320;
      final int inputHeight = inputTensor.shape.length > 2 ? inputTensor.shape[2] : 320;

      final params = _calculateLetterboxParams(image.width, image.height, inputWidth, inputHeight, rotation);

      final Float32List inputBuffer = Float32List(1 * inputWidth * inputHeight * 3);
      _convertYuvToRgbFloat32(image, inputBuffer, inputWidth, inputHeight, rotation, params);

      final input = inputBuffer.reshape([1, inputWidth, inputHeight, 3]);

      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;

      final outputMatrix = List.filled(outputShape.reduce((a, b) => a * b), 0.0).reshape(outputShape);
      final Map<int, Object> outputs = {0: outputMatrix};

      _interpreter!.runForMultipleInputs([input], outputs);

      final List<DetectedObjectBox> rawDetections = _decodeYoloV8Output(outputMatrix, outputShape, inputWidth, inputHeight, params);
      final List<DetectedObjectBox> finalDetections = _applyNMS(rawDetections, iouThreshold: 0.45);

      return finalDetections;
    } catch (e) {
      debugPrint('[GENUINE YOLOv8] Live camera frame detection error: $e');
      return [];
    }
  }

  _LetterboxParams _calculateLetterboxParams(int srcW, int srcH, int inputW, int inputH, int rotation) {
    final int visualW = (rotation == 90 || rotation == 270) ? srcH : srcW;
    final int visualH = (rotation == 90 || rotation == 270) ? srcW : srcH;

    final double scale = (inputW / visualW < inputH / visualH)
        ? inputW / visualW
        : inputH / visualH;

    final double wScaled = (visualW * scale).roundToDouble();
    final double hScaled = (visualH * scale).roundToDouble();

    final double padX = (inputW - wScaled) / 2.0;
    final double padY = (inputH - hScaled) / 2.0;

    return _LetterboxParams(
      scale: scale,
      padX: padX,
      padY: padY,
      wScaled: wScaled,
      hScaled: hScaled,
    );
  }

  void _convertYuvToRgbFloat32(
    CameraImage image,
    Float32List inputBuffer,
    int inputWidth,
    int inputHeight,
    int rotation,
    _LetterboxParams params,
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

    const double fillR = 114.0 / 255.0; // 0.4470588 (standard YOLO letterbox fill)
    const double fillG = 114.0 / 255.0;
    const double fillB = 114.0 / 255.0;

    int pixelIndex = 0;

    for (int y = 0; y < inputHeight; y++) {
      final double dy = y.toDouble();
      final bool isYInContent = dy >= params.padY && dy < (params.padY + params.hScaled);

      for (int x = 0; x < inputWidth; x++) {
        final double dx = x.toDouble();
        final bool isXInContent = dx >= params.padX && dx < (params.padX + params.wScaled);

        if (isYInContent && isXInContent) {
          final double xContent = dx - params.padX;
          final double yContent = dy - params.padY;

          final int uX = (xContent / params.scale).round().clamp(0, visualW - 1);
          final int uY = (yContent / params.scale).round().clamp(0, visualH - 1);

          int srcX;
          int srcY;

          if (rotation == 90) {
            srcX = (((visualH - 1 - uY) * (srcW - 1)) ~/ (visualH - 1)).clamp(0, srcW - 1);
            srcY = ((uX * (srcH - 1)) ~/ (visualW - 1)).clamp(0, srcH - 1);
          } else if (rotation == 270) {
            srcX = ((uY * (srcW - 1)) ~/ (visualH - 1)).clamp(0, srcW - 1);
            srcY = (((visualW - 1 - uX) * (srcH - 1)) ~/ (visualW - 1)).clamp(0, srcH - 1);
          } else {
            srcX = ((uX * (srcW - 1)) ~/ (visualW - 1)).clamp(0, srcW - 1);
            srcY = ((uY * (srcH - 1)) ~/ (visualH - 1)).clamp(0, srcH - 1);
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

          inputBuffer[pixelIndex++] = r;
          inputBuffer[pixelIndex++] = g;
          inputBuffer[pixelIndex++] = b;
        } else {
          inputBuffer[pixelIndex++] = fillR;
          inputBuffer[pixelIndex++] = fillG;
          inputBuffer[pixelIndex++] = fillB;
        }
      }
    }
  }

  /// Execute real on-device YOLOv8 inference on captured camera frame
  Future<List<DetectedObjectBox>> detectObjects(String imagePath) async {
    if (!_isInitialized) {
      await _initDetector();
      if (!_isInitialized || _interpreter == null) {
        debugPrint('[GENUINE YOLOv8] Detector is uninitialized.');
        return [];
      }
    }

    final stopwatch = Stopwatch()..start();

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[GENUINE YOLOv8] Image file does not exist: $imagePath');
        return [];
      }

      final Uint8List imageBytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('[GENUINE YOLOv8] Failed to decode camera frame image.');
        return [];
      }

      final inputTensor = _interpreter!.getInputTensor(0);
      final int inputWidth = inputTensor.shape.length > 2 ? inputTensor.shape[1] : 320;
      final int inputHeight = inputTensor.shape.length > 2 ? inputTensor.shape[2] : 320;

      final params = _calculateLetterboxParams(decodedImage.width, decodedImage.height, inputWidth, inputHeight, 0);

      // Preprocessing: Resize image with letterboxing to YOLOv8 input shape (320x320)
      final resizedImage = img.copyResize(
        decodedImage,
        width: params.wScaled.toInt(),
        height: params.hScaled.toInt(),
      );

      final Float32List inputBuffer = Float32List(1 * inputWidth * inputHeight * 3);
      const double fillR = 114.0 / 255.0;
      int pixelIndex = 0;

      for (int y = 0; y < inputHeight; y++) {
        final bool isYInContent = y >= params.padY && y < (params.padY + params.hScaled);
        for (int x = 0; x < inputWidth; x++) {
          final bool isXInContent = x >= params.padX && x < (params.padX + params.wScaled);

          if (isYInContent && isXInContent) {
            final int imgX = (x - params.padX).toInt().clamp(0, resizedImage.width - 1);
            final int imgY = (y - params.padY).toInt().clamp(0, resizedImage.height - 1);
            final pixel = resizedImage.getPixel(imgX, imgY);
            inputBuffer[pixelIndex++] = pixel.r / 255.0;
            inputBuffer[pixelIndex++] = pixel.g / 255.0;
            inputBuffer[pixelIndex++] = pixel.b / 255.0;
          } else {
            inputBuffer[pixelIndex++] = fillR;
            inputBuffer[pixelIndex++] = fillR;
            inputBuffer[pixelIndex++] = fillR;
          }
        }
      }

      final input = inputBuffer.reshape([1, inputWidth, inputHeight, 3]);

      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;

      final outputMatrix = List.filled(outputShape.reduce((a, b) => a * b), 0.0).reshape(outputShape);
      final Map<int, Object> outputs = {0: outputMatrix};

      _interpreter!.runForMultipleInputs([input], outputs);

      final List<DetectedObjectBox> rawDetections = _decodeYoloV8Output(outputMatrix, outputShape, inputWidth, inputHeight, params);
      final List<DetectedObjectBox> finalDetections = _applyNMS(rawDetections, iouThreshold: 0.45);

      stopwatch.stop();
      debugPrint('[GENUINE YOLOv8] YOLOv8 inference completed in ${stopwatch.elapsedMilliseconds} ms. Found ${finalDetections.length} objects.');

      return finalDetections;
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('[GENUINE YOLOv8] Detection execution error: $e');
      debugPrint('[GENUINE YOLOv8] StackTrace: $stackTrace');
      return [];
    }
  }

  /// Decode YOLOv8 Output Tensor Matrix [1, 84, 2100] or [1, 2100, 84]
  List<DetectedObjectBox> _decodeYoloV8Output(
    List matrix,
    List<int> shape,
    int inputW,
    int inputH,
    _LetterboxParams params,
  ) {
    final List<DetectedObjectBox> rawBoxes = [];
    const double confidenceThreshold = 0.35;
    final int numClasses = _labels.isNotEmpty ? _labels.length : 80;

    final bool isChannelsFirst = shape.length == 3 && shape[1] < shape[2]; // [1, 84, 2100]
    final int numAnchors = isChannelsFirst ? shape[2] : shape[1];
    final int numChannels = isChannelsFirst ? shape[1] : shape[2];

    for (int i = 0; i < numAnchors; i++) {
      double maxClassScore = 0.0;
      int bestClassIdx = -1;

      for (int c = 0; c < numClasses && (4 + c) < numChannels; c++) {
        final double score = isChannelsFirst
            ? (matrix[0][4 + c][i] as double)
            : (matrix[0][i][4 + c] as double);

        if (score > maxClassScore) {
          maxClassScore = score;
          bestClassIdx = c;
        }
      }

      if (maxClassScore >= confidenceThreshold && bestClassIdx != -1) {
        final double cx = isChannelsFirst ? (matrix[0][0][i] as double) : (matrix[0][i][0] as double);
        final double cy = isChannelsFirst ? (matrix[0][1][i] as double) : (matrix[0][i][1] as double);
        final double w = isChannelsFirst ? (matrix[0][2][i] as double) : (matrix[0][i][2] as double);
        final double h = isChannelsFirst ? (matrix[0][3][i] as double) : (matrix[0][i][3] as double);

        final double pixelCx = cx > 1.0 ? cx : cx * inputW;
        final double pixelCy = cy > 1.0 ? cy : cy * inputH;
        final double pixelW = w > 1.0 ? w : w * inputW;
        final double pixelH = h > 1.0 ? h : h * inputH;

        final double pixelLeft = pixelCx - pixelW / 2.0;
        final double pixelTop = pixelCy - pixelH / 2.0;
        final double pixelRight = pixelCx + pixelW / 2.0;
        final double pixelBottom = pixelCy + pixelH / 2.0;

        // Unpad and scale back to original camera view normalized coordinates [0.0, 1.0]
        final double left = ((pixelLeft - params.padX) / params.wScaled).clamp(0.0, 1.0);
        final double top = ((pixelTop - params.padY) / params.hScaled).clamp(0.0, 1.0);
        final double right = ((pixelRight - params.padX) / params.wScaled).clamp(0.0, 1.0);
        final double bottom = ((pixelBottom - params.padY) / params.hScaled).clamp(0.0, 1.0);

        final String label = bestClassIdx < _labels.length ? _labels[bestClassIdx] : 'object';

        rawBoxes.add(
          DetectedObjectBox(
            label: label,
            confidence: maxClassScore,
            left: left,
            top: top,
            right: right,
            bottom: bottom,
          ),
        );
      }
    }

    return rawBoxes;
  }

  /// Non-Maximum Suppression (NMS) IoU calculation
  List<DetectedObjectBox> _applyNMS(List<DetectedObjectBox> boxes, {double iouThreshold = 0.45}) {
    if (boxes.isEmpty) return [];

    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<DetectedObjectBox> selected = [];
    final List<bool> active = List.filled(boxes.length, true);

    for (int i = 0; i < boxes.length; i++) {
      if (!active[i]) continue;

      final boxA = boxes[i];
      selected.add(boxA);

      for (int j = i + 1; j < boxes.length; j++) {
        if (!active[j]) continue;

        final boxB = boxes[j];
        if (boxA.label == boxB.label) {
          final double iou = _calculateIoU(boxA, boxB);
          if (iou >= iouThreshold) {
            active[j] = false;
          }
        }
      }
    }

    return selected;
  }

  double _calculateIoU(DetectedObjectBox a, DetectedObjectBox b) {
    final double xMin = a.left > b.left ? a.left : b.left;
    final double yMin = a.top > b.top ? a.top : b.top;
    final double xMax = a.right < b.right ? a.right : b.right;
    final double yMax = a.bottom < b.bottom ? a.bottom : b.bottom;

    final double intersectionWidth = (xMax - xMin).clamp(0.0, 1.0);
    final double intersectionHeight = (yMax - yMin).clamp(0.0, 1.0);

    final double intersectionArea = intersectionWidth * intersectionHeight;
    if (intersectionArea <= 0) return 0.0;

    final double areaA = (a.right - a.left) * (a.bottom - a.top);
    final double areaB = (b.right - b.left) * (b.bottom - b.top);

    final double unionArea = areaA + areaB - intersectionArea;
    return unionArea > 0 ? intersectionArea / unionArea : 0.0;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
