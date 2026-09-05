import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/adiuva_card.dart';

/// Onboarding Step 1: Welcome & Core Assistance Overview
class Onboarding1Page extends StatelessWidget {
  const Onboarding1Page({super.key});

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
                Icons.accessibility_new_rounded,
                size: 56,
                color: AdiuvaColors.primaryTeal,
              ),
            ),
            AdiuvaSpacing.gapXl,
            Text(
              'Welcome to ADIUVA',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapMd,
            Text(
              'Your intelligent, accessible assistant designed for everyday independence and seamless interaction.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapXxl,
            AdiuvaCard(
              child: Padding(
                padding: AdiuvaSpacing.paddingMd,
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AdiuvaColors.primaryTeal, size: 28),
                    const SizedBox(width: AdiuvaSpacing.md),
                    Expanded(
                      child: Text(
                        'Tailored accessibility features built for visually, hearing, and speech-impaired users.',
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
