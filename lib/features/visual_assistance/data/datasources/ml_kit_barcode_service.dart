import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result entity for decoded barcode/QR data
class BarcodeScanResult {
  final String rawValue;
  final BarcodeType type;
  final String actionLabel;

  BarcodeScanResult({
    required this.rawValue,
    required this.type,
    required this.actionLabel,
  });
}

/// ML Kit Barcode & QR Code Scanner Service
class MlKitBarcodeService {
  BarcodeScanner? _barcodeScanner;

  MlKitBarcodeService() {
    _barcodeScanner = BarcodeScanner();
  }

  Future<BarcodeScanResult?> scanBarcode(String imagePath) async {
    _barcodeScanner ??= BarcodeScanner();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Barcode> barcodes = await _barcodeScanner!.processImage(inputImage);
      if (barcodes.isEmpty) {
        return null;
      }

      final barcode = barcodes.first;
      final rawValue = barcode.rawValue ?? barcode.displayValue ?? '';
      if (rawValue.isEmpty) return null;

      String actionLabel = 'Text Content';
      if (barcode.type == BarcodeType.url || rawValue.startsWith('http://') || rawValue.startsWith('https://')) {
        actionLabel = 'Website Link';
      } else if (barcode.type == BarcodeType.phone || rawValue.startsWith('tel:')) {
        actionLabel = 'Phone Number';
      } else if (barcode.type == BarcodeType.email || rawValue.startsWith('mailto:')) {
        actionLabel = 'Email Address';
      }

      return BarcodeScanResult(
        rawValue: rawValue,
        type: barcode.type,
        actionLabel: actionLabel,
      );
    } catch (e) {
      throw Exception('Failed to scan code: $e');
    }
  }

  /// Auto-launch URL or intent if valid
  Future<bool> launchBarcodeContent(String rawValue) async {
    try {
      Uri? uri;
      if (rawValue.startsWith('http://') || rawValue.startsWith('https://')) {
        uri = Uri.parse(rawValue);
      } else if (rawValue.startsWith('tel:')) {
        uri = Uri.parse(rawValue);
      } else if (rawValue.startsWith('mailto:')) {
        uri = Uri.parse(rawValue);
      } else if (RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b').hasMatch(rawValue)) {
        uri = Uri.parse('https://$rawValue');
      }

      if (uri != null && await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  void dispose() {
    _barcodeScanner?.close();
    _barcodeScanner = null;
  }
}
