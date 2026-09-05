import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/adiuva_card.dart';

/// Onboarding Step 2: Visual & AI Scene Assistance
class Onboarding2Page extends StatelessWidget {
  const Onboarding2Page({super.key});

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
                color: AdiuvaColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_red_eye_outlined,
                size: 56,
                color: AdiuvaColors.primaryTeal,
              ),
            ),
            AdiuvaSpacing.gapXl,
            Text(
              'Visual & AI Vision',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapMd,
            Text(
              'Describe scenes around you, extract printed text with OCR, detect objects, and scan codes instantly.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapXxl,
            AdiuvaCard(
              child: Padding(
                padding: AdiuvaSpacing.paddingMd,
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AdiuvaColors.primaryTeal, size: 28),
                    const SizedBox(width: AdiuvaSpacing.md),
                    Expanded(
                      child: Text(
                        'Powered by Firebase Gemini AI multimodal intelligence for rich real-world descriptions.',
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
