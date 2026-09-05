import 'package:google_ml_kit/google_ml_kit.dart';

/// ML Kit Object Detection & Image Labeling Service
class YoloDetectionService {
  ImageLabeler? _imageLabeler;

  YoloDetectionService() {
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
  }

  Future<List<String>> detectObjects(String imagePath) async {
    _imageLabeler ??= ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<ImageLabel> labels = await _imageLabeler!.processImage(inputImage);
      return labels.map((label) => label.label).toList();
    } catch (e) {
      throw Exception('Failed to detect objects in image: $e');
    }
  }

  void dispose() {
    _imageLabeler?.close();
    _imageLabeler = null;
  }
}
