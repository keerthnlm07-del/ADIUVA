import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';

/// Camera preview widget for real-time Indian Sign Language (ISL) gesture recognition
class SignCameraPreview extends StatelessWidget {
  final CameraController? cameraController;
  final bool isCameraInitialized;
  final bool isRecognizing;
  final VoidCallback onToggleCamera;

  const SignCameraPreview({
    super.key,
    required this.cameraController,
    required this.isCameraInitialized,
    required this.isRecognizing,
    required this.onToggleCamera,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? AdiuvaColors.darkSurface : AdiuvaColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecognizing ? AdiuvaColors.primaryTeal : (isDark ? AdiuvaColors.darkBorder : AdiuvaColors.lightBorder),
          width: isRecognizing ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCameraInitialized && cameraController != null && cameraController!.value.isInitialized)
            AspectRatio(
              aspectRatio: cameraController!.value.aspectRatio,
              child: CameraPreview(cameraController!),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  size: 54,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                AdiuvaSpacing.gapSm,
                Text(
                  isCameraInitialized ? 'Camera Stopped' : 'Initializing Camera...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AdiuvaSpacing.gapXs,
                Text(
                  'Tap "Start Recognition" to activate camera',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),

          // Top Status Badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isRecognizing ? Colors.green.shade700 : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRecognizing ? Colors.greenAccent : Colors.grey.shade400,
                    ),
                  ),
                  AdiuvaSpacing.gapXs,
                  Text(
                    isRecognizing ? 'RECOGNIZING LIVE' : 'CAMERA READY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Right Camera Switch Button
          Positioned(
            top: 10,
            right: 10,
            child: IconButton.filledTonal(
              icon: const Icon(Icons.cameraswitch_rounded, size: 20),
              onPressed: onToggleCamera,
              tooltip: 'Switch Camera',
            ),
          ),
        ],
      ),
    );
  }
}
