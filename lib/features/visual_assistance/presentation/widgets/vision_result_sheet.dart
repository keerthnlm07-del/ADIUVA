import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/theme/adiuva_radius.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/vision_result.dart';
import '../provider/visual_assistance_provider.dart';

/// Vision Analysis Result Bottom Sheet Component
class VisionResultSheet extends StatelessWidget {
  final VisionResult result;
  final VisualAssistanceProvider provider;
  final VoidCallback onClose;
  final Function(String query)? onAskAssistant;

  const VisionResultSheet({
    super.key,
    required this.result,
    required this.provider,
    required this.onClose,
    this.onAskAssistant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      focused: true,
      label: '${result.title}: ${result.text}',
      child: Container(
        padding: AdiuvaSpacing.paddingLg,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: AdiuvaRadius.borderRadiusPill,
                  ),
                ),
              ),
              AdiuvaSpacing.gapLg,

              // Header: Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          result.isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: result.isError ? AdiuvaColors.error : AdiuvaColors.primaryTeal,
                          size: 28,
                        ),
                        const SizedBox(width: AdiuvaSpacing.md),
                        Text(
                          result.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: result.isError ? AdiuvaColors.error : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Close result sheet and retake picture',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onClose,
                    ),
                  ),
                ],
              ),
              AdiuvaSpacing.gapMd,

              // Selectable Result Text Body
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: SelectableText(
                    result.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              AdiuvaSpacing.gapXl,

              // Action Buttons Row (Read Aloud, Copy, Ask ADIUVA, Retake)
              Wrap(
                spacing: AdiuvaSpacing.md,
                runSpacing: AdiuvaSpacing.md,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  // Read Aloud Action Button
                  CustomButton.secondary(
                    label: provider.isSpeaking ? 'Stop Reading' : 'Read Aloud',
                    leadingIcon: provider.isSpeaking ? Icons.stop_rounded : Icons.volume_up_outlined,
                    onPressed: () {
                      if (provider.isSpeaking) {
                        provider.stopSpeaking();
                      } else {
                        provider.speakResult();
                      }
                    },
                  ),

                  // Copy Action Button
                  CustomButton.outlined(
                    label: 'Copy Text',
                    leadingIcon: Icons.copy_outlined,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.text));
                      AccessibilityScaffold.announce('Result text copied to clipboard.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Result copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  // Retake Button
                  CustomButton.primary(
                    label: 'Retake',
                    leadingIcon: Icons.camera_alt_outlined,
                    onPressed: onClose,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
