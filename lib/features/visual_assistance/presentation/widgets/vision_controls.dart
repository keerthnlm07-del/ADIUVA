import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/theme/adiuva_radius.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../domain/entities/vision_result.dart';
import '../provider/visual_assistance_provider.dart';

/// Vision Camera Overlay Controls Component
class VisionControls extends StatelessWidget {
  final VisualAssistanceProvider provider;
  final VoidCallback onCapture;

  const VisionControls({
    super.key,
    required this.provider,
    required this.onCapture,
  });

  String _getModeName(VisionMode mode) {
    switch (mode) {
      case VisionMode.describeScene:
        return 'Describe Scene';
      case VisionMode.readText:
        return 'Read Text';
      case VisionMode.identifyObject:
        return 'Identify Object';
      case VisionMode.scanCode:
        return 'Scan Code';
    }
  }

  IconData _getModeIcon(VisionMode mode) {
    switch (mode) {
      case VisionMode.describeScene:
        return Icons.remove_red_eye_outlined;
      case VisionMode.readText:
        return Icons.document_scanner_outlined;
      case VisionMode.identifyObject:
        return Icons.label_outlined;
      case VisionMode.scanCode:
        return Icons.qr_code_scanner_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = provider.state == VisionStateEnum.processing ||
        provider.state == VisionStateEnum.capturing;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Bar: Flash & Speak Last Result
        Padding(
          padding: const EdgeInsets.all(AdiuvaSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flash Toggle Button
              Semantics(
                label: provider.isFlashOn ? 'Turn Flash Off' : 'Turn Flash On',
                button: true,
                child: SizedBox(
                  width: AdiuvaSpacing.minTouchTarget,
                  height: AdiuvaSpacing.minTouchTarget,
                  child: IconButton.filledTonal(
                    icon: Icon(
                      provider.isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: provider.isFlashOn ? AdiuvaColors.voiceAmber : Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () {
                      provider.toggleFlash();
                      AccessibilityScaffold.announce(
                        provider.isFlashOn ? 'Flash turned off' : 'Flash turned on',
                      );
                    },
                  ),
                ),
              ),

              // Speak Last Result Button
              if (provider.lastResult != null)
                Semantics(
                  label: 'Read last vision result aloud',
                  button: true,
                  child: SizedBox(
                    width: AdiuvaSpacing.minTouchTarget,
                    height: AdiuvaSpacing.minTouchTarget,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: AdiuvaColors.primaryTeal,
                      ),
                      onPressed: () {
                        provider.speakResult();
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Bottom Controls Container
        Container(
          padding: const EdgeInsets.all(AdiuvaSpacing.lg),
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Horizontal Mode Selector Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: VisionMode.values.map((mode) {
                      final isSelected = provider.currentMode == mode;
                      return Padding(
                        padding: const EdgeInsets.only(right: AdiuvaSpacing.sm),
                        child: Semantics(
                          selected: isSelected,
                          label: '${_getModeName(mode)} mode',
                          hint: 'Double tap to select ${_getModeName(mode)} mode',
                          child: ChoiceChip(
                            showCheckmark: false,
                            avatar: Icon(
                              _getModeIcon(mode),
                              size: 20,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            label: Text(
                              _getModeName(mode),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AdiuvaColors.primaryTeal,
                            backgroundColor: Colors.white12,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AdiuvaRadius.borderRadiusPill,
                              side: isSelected
                                  ? const BorderSide(color: Colors.white, width: 2)
                                  : BorderSide.none,
                            ),
                            onSelected: (_) {
                              provider.selectMode(mode);
                              AccessibilityScaffold.announce('Selected ${_getModeName(mode)} mode');
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AdiuvaSpacing.gapLg,

                // Live Continuous Scanning Status Indicator
                if (provider.currentMode == VisionMode.identifyObject) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AdiuvaSpacing.md),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: provider.isContinuousMonitoring
                          ? AdiuvaColors.primaryTeal.withValues(alpha: 0.25)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: provider.isContinuousMonitoring ? AdiuvaColors.primaryTeal : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.isContinuousMonitoring ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                          size: 16,
                          color: provider.isContinuousMonitoring ? AdiuvaColors.primaryTeal : Colors.white54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.isContinuousMonitoring ? 'Continuous Scanning Active' : 'Scanning Paused',
                          style: TextStyle(
                            color: provider.isContinuousMonitoring ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Shutter / Capture Button & Import Document Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pause / Resume Live Scanning Toggle (Shown in Identify Object mode)
                    if (provider.currentMode == VisionMode.identifyObject) ...[
                      Semantics(
                        label: provider.isContinuousMonitoring
                            ? 'Pause continuous object scanning'
                            : 'Resume continuous object scanning',
                        button: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'vision_toggle_monitoring_button',
                                onPressed: () {
                                  provider.toggleContinuousMonitoring();
                                  AccessibilityScaffold.announce(
                                    provider.isContinuousMonitoring
                                        ? 'Continuous scanning resumed'
                                        : 'Continuous scanning paused',
                                  );
                                },
                                backgroundColor: provider.isContinuousMonitoring
                                    ? AdiuvaColors.primaryTeal.withValues(alpha: 0.3)
                                    : Colors.white24,
                                elevation: 4,
                                shape: const CircleBorder(),
                                child: Icon(
                                  provider.isContinuousMonitoring ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.isContinuousMonitoring ? 'Pause' : 'Resume',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AdiuvaSpacing.lg),
                    ],

                    // Shutter / Capture Button
                    Semantics(
                      label: 'Capture image for ${_getModeName(provider.currentMode)}',
                      button: true,
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: FloatingActionButton(
                          heroTag: 'vision_shutter_button',
                          onPressed: isProcessing ? null : onCapture,
                          backgroundColor: provider.currentMode == VisionMode.describeScene
                              ? AdiuvaColors.voiceAmber
                              : AdiuvaColors.primaryTeal,
                          elevation: 6,
                          shape: const CircleBorder(),
                          child: isProcessing
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 3,
                                )
                              : const Icon(
                                  Icons.camera_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),

                    // Import Document Button (Shown in Read Text mode)
                    if (provider.currentMode == VisionMode.readText) ...[
                      const SizedBox(width: AdiuvaSpacing.lg),
                      Semantics(
                        label: 'Import Document from storage',
                        button: true,
                        hint: 'Double tap to select PDF or image document from device',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'vision_import_doc_button',
                                onPressed: isProcessing ? null : () => provider.importDocument(),
                                backgroundColor: Colors.white24,
                                elevation: 4,
                                shape: const CircleBorder(),
                                child: const Icon(
                                  Icons.file_upload_outlined,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Import',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Gallery / Pick Image Button (Shown in Identify Object mode)
                    if (provider.currentMode == VisionMode.identifyObject) ...[
                      const SizedBox(width: AdiuvaSpacing.lg),
                      Semantics(
                        label: 'Select photo from gallery or storage to identify object',
                        button: true,
                        hint: 'Double tap to select an image from your device',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'vision_pick_image_button',
                                onPressed: isProcessing ? null : () => provider.pickAndIdentifyObject(),
                                backgroundColor: Colors.white24,
                                elevation: 4,
                                shape: const CircleBorder(),
                                child: const Icon(
                                  Icons.photo_library_outlined,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Gallery',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
