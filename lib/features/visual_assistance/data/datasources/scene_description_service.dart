import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:image/image.dart' as img;

/// Firebase AI Gemini Multimodal Scene Description Service
class SceneDescriptionService {
  GenerativeModel? _generativeModel;

  SceneDescriptionService() {
    _initModel();
  }

  void _initModel() {
    if (_generativeModel != null) return;
    try {
      final stopwatch = Stopwatch()..start();
      _generativeModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
      );
      stopwatch.stop();
      debugPrint('[MULTIMODAL GEMINI] Model (gemini-3.8-flash) initialized in ${stopwatch.elapsedMilliseconds} ms');
    } catch (e, stackTrace) {
      debugPrint('[MULTIMODAL GEMINI] Model init error: $e');
      debugPrint('[MULTIMODAL GEMINI] StackTrace: $stackTrace');
    }
  }

  /// Compress and downscale captured image to optimize payload size for mobile networks
  Future<Uint8List> _optimizeImagePayload(Uint8List originalBytes) async {
    return compute((Uint8List bytes) {
      try {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) return bytes;

        const int maxDimension = 800;
        img.Image resized = decoded;

        if (decoded.width > maxDimension || decoded.height > maxDimension) {
          if (decoded.width >= decoded.height) {
            resized = img.copyResize(decoded, width: maxDimension);
          } else {
            resized = img.copyResize(decoded, height: maxDimension);
          }
        }

        final compressedJpg = img.encodeJpg(resized, quality: 75);
        return Uint8List.fromList(compressedJpg);
      } catch (e) {
        return bytes;
      }
    }, originalBytes);
  }

  Future<String> describeScene(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[MULTIMODAL GEMINI] REQUEST START for image: $imagePath');

    try {
      _initModel();

      if (_generativeModel == null) {
        throw Exception('Gemini AI model is uninitialized.');
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Captured image file does not exist.');
      }

      final Uint8List rawImageBytes = await file.readAsBytes();
      final double rawKb = rawImageBytes.lengthInBytes / 1024;

      final Uint8List optimizedBytes = await _optimizeImagePayload(rawImageBytes);
      final double optKb = optimizedBytes.lengthInBytes / 1024;

      debugPrint('[MULTIMODAL GEMINI] Image payload optimized: ${rawKb.toStringAsFixed(1)} KB -> ${optKb.toStringAsFixed(1)} KB (in ${stopwatch.elapsedMilliseconds} ms)');

      debugPrint('[MULTIMODAL GEMINI] SENDING MULTIMODAL REQUEST to gemini-3.8-flash...');

      const promptText = 
          'Describe this scene in one or two short, simple sentences for a blind or visually impaired person. '
          'Focus only on the main object, person, or physical layout. '
          'Do NOT include confidence scores, percentages, bounding boxes, or technical object lists. '
          'Be concise, clear, and natural.';

      final response = await _generativeModel!.generateContent([
        Content.inlineData('image/jpeg', optimizedBytes),
        Content.text(promptText),
      ]).timeout(const Duration(seconds: 45));

      stopwatch.stop();
      debugPrint('[MULTIMODAL GEMINI] RESPONSE RECEIVED in ${stopwatch.elapsedMilliseconds} ms');

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw Exception('No description generated from Gemini.');
      }

      return text;
    } on TimeoutException catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('[MULTIMODAL GEMINI] REQUEST TIMEOUT after ${stopwatch.elapsedMilliseconds} ms: $e');
      debugPrint('[MULTIMODAL GEMINI] StackTrace: $stackTrace');
      throw Exception("I couldn't describe the scene. Please try again.");
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('[MULTIMODAL GEMINI] REQUEST ERROR after ${stopwatch.elapsedMilliseconds} ms: $e');
      debugPrint('[MULTIMODAL GEMINI] StackTrace: $stackTrace');
      throw Exception("I couldn't describe the scene. Please try again.");
    }
  }
}
