import 'package:flutter/material.dart';
import '../../data/datasources/yolo_tflite_service.dart';

/// Overlay widget rendering live bounding boxes over camera feed
class BoundingBoxOverlay extends StatelessWidget {
  final List<DetectedObjectBox> boxes;
  final Size previewSize;

  const BoundingBoxOverlay({
    super.key,
    required this.boxes,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      size: Size.infinite,
      painter: _BoundingBoxPainter(
        boxes: boxes,
        previewSize: previewSize,
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<DetectedObjectBox> boxes;
  final Size previewSize;

  _BoundingBoxPainter({
    required this.boxes,
    required this.previewSize,
  });

  // Palette of high-contrast colors for bounding box categories
  static const List<Color> _colors = [
    Color(0xFF00E676), // Bright Green
    Color(0xFF00E5FF), // Cyan
    Color(0xFFFFEA00), // Yellow
    Color(0xFFFF9100), // Orange
    Color(0xFFFF4081), // Pink
    Color(0xFFE040FB), // Purple
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (int i = 0; i < boxes.length; i++) {
      final box = boxes[i];
      final color = _colors[i % _colors.length];

      // Convert normalized [0.0, 1.0] coordinates to canvas dimensions
      final double left = box.left * size.width;
      final double top = box.top * size.height;
      final double right = box.right * size.width;
      final double bottom = box.bottom * size.height;
      final double width = right - left;
      final double height = bottom - top;

      if (width <= 0 || height <= 0) continue;

      final rect = Rect.fromLTWH(left, top, width, height);

      // 1. Draw outer stroke rectangle
      final paintRect = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rrect, paintRect);

      // 2. Draw subtle translucent box background fill
      final paintFill = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, paintFill);

      // 3. Draw accessibility label header
      final String label = box.label.replaceAll('_', ' ').toLowerCase();
      final TextSpan span = TextSpan(
        text: ' $label ',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      );

      final TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      final double labelHeight = tp.height + 6;
      final double labelWidth = tp.width + 12;
      final double labelTop = (top - labelHeight) < 0 ? top : (top - labelHeight);

      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, labelTop, labelWidth, labelHeight),
        const Radius.circular(6),
      );

      final paintLabelBg = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(labelRect, paintLabelBg);
      tp.paint(canvas, Offset(left + 6, labelTop + 3));
    }
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes || oldDelegate.previewSize != previewSize;
  }
}
