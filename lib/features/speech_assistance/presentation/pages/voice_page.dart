import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../config/routes/app_routes.dart';
import '../provider/voice_mode_provider.dart';
import '../widgets/voice_button_widget.dart';

/// ADIUVA Voice Mode Page
class VoicePage extends StatefulWidget {
  const VoicePage({super.key});

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  @override
  void dispose() {
    // Ensure active TTS/STT stops when leaving Voice Page
    super.dispose();
  }

  String _getStateTitle(VoiceStateEnum state) {
    switch (state) {
      case VoiceStateEnum.idle:
        return 'Tap Button to Start';
      case VoiceStateEnum.listening:
        return 'Listening...';
      case VoiceStateEnum.processing:
        return 'Thinking...';
      case VoiceStateEnum.speaking:
        return 'Speaking Response';
      case VoiceStateEnum.paused:
        return 'Session Paused';
      case VoiceStateEnum.error:
        return 'Error Occurred';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<VoiceModeProvider>(context);
    final state = provider.state;

    if (provider.pendingNavigationRoute != null) {
      final routeName = provider.pendingNavigationRoute!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearNavigationRoute();
        if (mounted) {
          Navigator.of(context).pushNamed(routeName);
        }
      });
    }

    return AccessibilityScaffold(
      pageTitle: 'Voice Assistant Mode',
      appBar: CustomAppBar(
        title: 'Voice Mode',
        showBackButton: true,
        onBackPressed: () {
          provider.stopSession();
          Navigator.of(context).pop();
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AdiuvaSpacing.gapLg,

            // Active Voice State Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: state == VoiceStateEnum.listening
                    ? AdiuvaColors.voiceContainer
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStateTitle(state),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: state == VoiceStateEnum.listening
                      ? AdiuvaColors.onVoiceContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            AdiuvaSpacing.gapXxl,

            // 96dp Signature Voice Button Widget
            VoiceButtonWidget(
              state: state,
              onTap: () {
                provider.toggleVoiceSession();
              },
            ),
            AdiuvaSpacing.gapXxl,

            // Live Transcript Box
            if (provider.liveTranscript.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Words',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AdiuvaSpacing.gapSm,
              AdiuvaCard(
                padding: AdiuvaSpacing.paddingLg,
                backgroundColor: AdiuvaColors.voiceContainer.withValues(alpha: 0.5),
                child: SelectableText(
                  provider.liveTranscript,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AdiuvaSpacing.gapLg,
            ],

            // Assistant Response Box
            if (provider.assistantResponse.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ADIUVA Response',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              AdiuvaSpacing.gapSm,
              AdiuvaCard(
                padding: AdiuvaSpacing.paddingLg,
                child: SelectableText(
                  provider.assistantResponse,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
              AdiuvaSpacing.gapLg,
            ],

            // Error Message Box
            if (provider.errorMessage != null) ...[
              AdiuvaCard(
                padding: AdiuvaSpacing.paddingLg,
                backgroundColor: theme.colorScheme.errorContainer,
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 28),
                    const SizedBox(width: AdiuvaSpacing.md),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AdiuvaSpacing.gapLg,
            ],

            // Bottom Actions (Type Instead & Reset)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: CustomButton.outlined(
                    label: 'Type Instead',
                    leadingIcon: Icons.keyboard_outlined,
                    onPressed: () {
                      provider.stopSession();
                      Navigator.of(context).pushReplacementNamed(AppRoutes.aiAssistant);
                    },
                  ),
                ),
                const SizedBox(width: AdiuvaSpacing.md),
                Expanded(
                  child: CustomButton.secondary(
                    label: 'Reset Session',
                    leadingIcon: Icons.refresh_outlined,
                    onPressed: () {
                      provider.reset();
                      AccessibilityScaffold.announce('Voice session reset.');
                    },
                  ),
                ),
              ],
            ),
            AdiuvaSpacing.gapLg,
          ],
        ),
      ),
    );
  }
}
