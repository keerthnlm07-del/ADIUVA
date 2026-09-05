import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../provider/visual_assistance_provider.dart';
import '../widgets/camera_preview.dart';
import '../widgets/vision_controls.dart';
import '../widgets/vision_result_sheet.dart';

/// ADIUVA Visual Assistance Suite Page
class VisualAssistancePage extends StatefulWidget {
  const VisualAssistancePage({super.key});

  @override
  State<VisualAssistancePage> createState() => _VisualAssistancePageState();
}

class _VisualAssistancePageState extends State<VisualAssistancePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VisualAssistanceProvider>(context, listen: false);
      if (provider.state == VisionStateEnum.idle) {
        provider.initializeCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VisualAssistanceProvider>(context);

    return AccessibilityScaffold(
      pageTitle: 'Vision Assistance Suite',
      padding: EdgeInsets.zero, // Full edge-to-edge camera layout
      body: Stack(
        children: [
          // 1. Camera Preview
          Positioned.fill(
            child: CameraPreviewWidget(provider: provider),
          ),

          // 2. Permission Denied View
          if (provider.state == VisionStateEnum.permissionDenied)
            Positioned.fill(
              child: _buildPermissionDeniedView(context, provider),
            ),

          // 3. Vision Overlay Controls
          if (provider.state != VisionStateEnum.permissionDenied)
            Positioned.fill(
              child: VisionControls(
                provider: provider,
                onCapture: () => provider.captureAndProcess(),
              ),
            ),

          // 4. Result Bottom Sheet Overlay
          if (provider.lastResult != null && provider.lastResult!.mode == provider.currentMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VisionResultSheet(
                result: provider.lastResult!,
                provider: provider,
                onClose: () => provider.clearResult(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView(
    BuildContext context,
    VisualAssistanceProvider provider,
  ) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: AdiuvaSpacing.paddingLg,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AdiuvaColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_enhance_outlined,
                  size: 48,
                  color: AdiuvaColors.primaryTeal,
                ),
              ),
              AdiuvaSpacing.gapXl,
              Text(
                'Camera Access Required',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapMd,
              Text(
                'ADIUVA needs camera permission to describe surroundings, extract text, and recognize objects for you.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapXxl,
              AdiuvaCard(
                child: Padding(
                  padding: AdiuvaSpacing.paddingMd,
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: AdiuvaColors.primaryTeal, size: 28),
                      const SizedBox(width: AdiuvaSpacing.md),
                      Expanded(
                        child: Text(
                          'Your privacy is protected. Images are processed directly for live assistance.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AdiuvaSpacing.gapXxl,

              CustomButton.primary(
                label: 'Grant Camera Permission',
                leadingIcon: Icons.camera_alt_outlined,
                onPressed: () => provider.initializeCamera(),
              ),
              AdiuvaSpacing.gapMd,
              CustomButton.secondary(
                label: 'Open App Settings',
                leadingIcon: Icons.settings_outlined,
                onPressed: () => provider.openSettings(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
