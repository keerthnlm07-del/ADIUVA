import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/adiuva_card.dart';

/// Onboarding Step 4: Personalization & Ready to Begin
class Onboarding4Page extends StatelessWidget {
  const Onboarding4Page({super.key});

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
                Icons.tune_outlined,
                size: 56,
                color: AdiuvaColors.primaryTeal,
              ),
            ),
            AdiuvaSpacing.gapXl,
            Text(
              'Personalize Your Experience',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapMd,
            Text(
              'Customize high-contrast modes, font sizes, screen reader announcements, and voice settings anytime.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapXxl,
            AdiuvaCard(
              child: Padding(
                padding: AdiuvaSpacing.paddingMd,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AdiuvaColors.primaryTeal, size: 28),
                    const SizedBox(width: AdiuvaSpacing.md),
                    Expanded(
                      child: Text(
                        'You are ready to get started! Sign in or create an account to save your accessibility profile.',
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
