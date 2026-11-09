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
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    result.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              AdiuvaSpacing.gapMd,

              // Detected / Classified Object Labels
              if (result.labels.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: result.labels.map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                AdiuvaSpacing.gapMd,
              ],

              // Document Multi-Page Navigation & AI Story Summary Controls
              if (provider.hasActiveDocument) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Page Navigation Controls Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Semantics(
                            label: 'Previous Page',
                            button: true,
                            enabled: provider.activeDocument!.hasPreviousPage,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded),
                              onPressed: provider.activeDocument!.hasPreviousPage
                                  ? () => provider.previousPage()
                                  : null,
                            ),
                          ),
                          Text(
                            'Page ${provider.activeDocument!.currentPageIndex + 1} of ${provider.activeDocument!.totalPages}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Semantics(
                            label: 'Next Page',
                            button: true,
                            enabled: provider.activeDocument!.hasNextPage,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded),
                              onPressed: provider.activeDocument!.hasNextPage
                                  ? () => provider.nextPage()
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 12),

                      // Document Playback & AI Story Summary Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Start / Pause / Resume Playback Button
                          Semantics(
                            label: provider.isReadingDocument
                                ? 'Pause Reading'
                                : (provider.isDocumentPaused ? 'Resume Reading' : 'Start Reading'),
                            button: true,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdiuvaColors.primaryTeal,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                if (provider.isReadingDocument) {
                                  provider.pauseReadingDocument();
                                } else if (provider.isDocumentPaused) {
                                  provider.resumeReadingDocument();
                                } else {
                                  provider.startReadingDocument();
                                }
                              },
                              icon: Icon(
                                provider.isReadingDocument
                                    ? Icons.pause_rounded
                                    : (provider.isDocumentPaused ? Icons.play_arrow_rounded : Icons.play_arrow_rounded),
                              ),
                              label: Text(
                                provider.isReadingDocument
                                    ? 'Pause'
                                    : (provider.isDocumentPaused ? 'Resume' : 'Start Reading'),
                              ),
                            ),
                          ),

                          // AI Story Summary Button
                          Semantics(
                            label: 'What is this story about? Summarize with AI',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: provider.isSummarizingDocument
                                  ? null
                                  : () => provider.summarizeActiveDocument(),
                              icon: provider.isSummarizingDocument
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.auto_awesome_rounded, color: AdiuvaColors.voiceAmber),
                              label: const Text('Story Summary'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AdiuvaSpacing.gapMd,
              ],

              // Action Buttons Row (Read Aloud, Copy, Retake)
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

                  // Retake / Clear Button
                  CustomButton.primary(
                    label: provider.hasActiveDocument ? 'Close Doc' : 'Retake',
                    leadingIcon: provider.hasActiveDocument ? Icons.close_rounded : Icons.camera_alt_outlined,
                    onPressed: () {
                      if (provider.hasActiveDocument) {
                        provider.clearDocument();
                      }
                      onClose();
                    },
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
