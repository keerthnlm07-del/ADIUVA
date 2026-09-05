import 'package:equatable/equatable.dart';

/// Vision Analysis Modes
enum VisionMode {
  describeScene,
  readText,
  identifyObject,
  scanCode,
}

/// Vision Result Entity representing analysis results
class VisionResult extends Equatable {
  final VisionMode mode;
  final String title;
  final String text;
  final List<String> labels;
  final DateTime timestamp;
  final bool isError;
  final String? imagePath;

  const VisionResult({
    required this.mode,
    required this.title,
    required this.text,
    this.labels = const [],
    required this.timestamp,
    this.isError = false,
    this.imagePath,
  });

  @override
  List<Object?> get props => [mode, title, text, labels, timestamp, isError, imagePath];
}
