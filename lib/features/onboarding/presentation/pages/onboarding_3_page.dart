import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/adiuva_card.dart';

/// Onboarding Step 3: Voice & Audio Interaction
class Onboarding3Page extends StatelessWidget {
  const Onboarding3Page({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: AdiuvaSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AdiuvaSpacing.gapLg,
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AdiuvaColors.voiceContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_none_outlined,
                size: 56,
                color: AdiuvaColors.voiceAmberDark,
              ),
            ),
            AdiuvaSpacing.gapXl,
            Text(
              'Voice Assistant Mode',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AdiuvaColors.voiceAmberDark,
              ),
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapMd,
            Text(
              'Speak hands-free with high-contrast Sand & Amber voice mode, real-time speech recognition, and instant TTS audio feedback.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapXxl,
            AdiuvaCard(
              child: Padding(
                padding: AdiuvaSpacing.paddingMd,
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq, color: AdiuvaColors.voiceAmber, size: 28),
                    const SizedBox(width: AdiuvaSpacing.md),
                    Expanded(
                      child: Text(
                        'Pulsing visual audio feedback and customizable speech speed for screen reader users.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
