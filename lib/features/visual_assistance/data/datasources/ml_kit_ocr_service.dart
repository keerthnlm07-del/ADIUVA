import 'package:google_ml_kit/google_ml_kit.dart';

/// ML Kit Text Recognition (OCR) Service
class MlKitOcrService {
  TextRecognizer? _textRecognizer;

  MlKitOcrService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  Future<String> recognizeText(String imagePath) async {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Alias for recognizeText
  Future<String> extractText(String imagePath) async {
    return await recognizeText(imagePath);
  }

  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
