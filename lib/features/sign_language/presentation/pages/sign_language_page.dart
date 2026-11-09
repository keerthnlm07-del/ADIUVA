import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../config/routes/app_routes.dart';

/// Sign Language Home Screen
/// Provides two distinct entry points for Indian Sign Language (ISL) communication:
/// 1. Sign Language to Text (Camera recognition of signing -> text & speech)
/// 2. Text to Sign Language (Typed/spoken text -> 3D avatar & genuine ISL video playback)
class SignLanguagePage extends StatelessWidget {
  const SignLanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AccessibilityScaffold(
      pageTitle: 'Indian Sign Language (ISL)',
      appBar: const CustomAppBar(
        title: 'Sign Language (ISL)',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AdiuvaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Header
            Text(
              'Indian Sign Language Communication',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AdiuvaSpacing.gapXs,
            Text(
              'Select a communication workflow:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AdiuvaSpacing.gapLg,

            // Option 1: Sign Language to Text
            Semantics(
              label: 'Sign Language to Text. Point camera at someone signing to translate gestures into text and speech.',
              button: true,
              child: AdiuvaCard(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.signToText);
                },
                child: Padding(
                  padding: const EdgeInsets.all(AdiuvaSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AdiuvaColors.primaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.camera_front_rounded,
                          size: 36,
                          color: AdiuvaColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(width: AdiuvaSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign Language to Text',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Capture live signing with camera to recognize ISL gestures and convert to readable text and speech.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.bolt_rounded, size: 16, color: AdiuvaColors.primaryTeal),
                                const SizedBox(width: 4),
                                Text(
                                  '28 Live Recognized Signs',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AdiuvaColors.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            AdiuvaSpacing.gapMd,

            // Option 2: Text to Sign Language
            Semantics(
              label: 'Text to Sign Language. Type or speak words to watch genuine ISL video demonstrations.',
              button: true,
              child: AdiuvaCard(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.textToSign);
                },
                child: Padding(
                  padding: const EdgeInsets.all(AdiuvaSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          size: 36,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: AdiuvaSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Text to Sign Language',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type or speak a message to watch genuine video demonstrations performed by human signers.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.videocam_rounded, size: 16, color: Colors.indigo),
                                const SizedBox(width: 4),
                                const Text(
                                  '61 Genuine ISL Video Clips',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            AdiuvaSpacing.gapXl,

            // Accessibility Voice Commands Guidance Card
            Container(
              padding: const EdgeInsets.all(AdiuvaSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AdiuvaColors.darkSurface : AdiuvaColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AdiuvaColors.darkBorder : AdiuvaColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mic_rounded, size: 20, color: AdiuvaColors.voiceAmberDark),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Navigation',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can say:\n'
                    '• "Open Sign to Text" or "Sign Language to Text"\n'
                    '• "Open Text to Sign" or "Text to Sign Language"\n'
                    '• "Demonstrate sign for Hello" (or any word)\n'
                    '• "Go Back" or "Go Home"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
