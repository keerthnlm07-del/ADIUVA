import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../provider/visual_assistance_provider.dart';
import '../../domain/entities/vision_result.dart';
import 'bounding_box_overlay.dart';

/// Camera Preview Container Widget with Real-Time Bounding Box Overlay
class CameraPreviewWidget extends StatelessWidget {
  final VisualAssistanceProvider provider;

  const CameraPreviewWidget({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final controller = provider.cameraController;

    if (provider.state == VisionStateEnum.permissionDenied) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: Colors.white54,
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AdiuvaColors.primaryTeal),
              ),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      excludeSemantics: true, // Hide raw video frame stream from screen reader
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),

          // 2. Real-Time YOLO Bounding Box Overlay
          if (provider.currentMode == VisionMode.identifyObject)
            Positioned.fill(
              child: BoundingBoxOverlay(
                boxes: provider.liveBoundingBoxes,
                previewSize: controller.value.previewSize ?? Size.zero,
              ),
            ),
        ],
      ),
    );
  }
}
