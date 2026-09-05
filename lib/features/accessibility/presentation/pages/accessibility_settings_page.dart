import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../provider/accessibility_provider.dart';

/// ADIUVA Accessibility Settings Page
class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AccessibilityProvider>(context);

    return AccessibilityScaffold(
      pageTitle: 'Accessibility Settings',
      appBar: const CustomAppBar(title: 'Accessibility Settings'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Text & Typography Preview Section
            Text(
              'Live Text Preview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapSm,
            AdiuvaCard(
              padding: AdiuvaSpacing.paddingLg,
              backgroundColor: AdiuvaColors.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Heading (${(provider.fontScale * 100).toInt()}%)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18 * provider.fontScale,
                      fontWeight: provider.isBoldText ? FontWeight.w900 : FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ADIUVA empowers your visual, speech, and navigation independence with high legibility and voice feedback.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14 * provider.fontScale,
                      fontWeight: provider.isBoldText ? FontWeight.bold : FontWeight.normal,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapXl,

            // Text Scaling & Typography Section
            Text(
              'Text Size & Typography',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Font Scale Selector (100% - 200%)
            AdiuvaCard(
              padding: AdiuvaSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text Scale: ${(provider.fontScale * 100).toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildScaleChip(context, provider, 1.0, '100% Standard'),
                      _buildScaleChip(context, provider, 1.25, '125% Large'),
                      _buildScaleChip(context, provider, 1.5, '150% X-Large'),
                      _buildScaleChip(context, provider, 2.0, '200% Max'),
                    ],
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Bold Text Toggle
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Bold Text', style: theme.textTheme.titleMedium),
                subtitle: const Text('Apply extra weight to all text for maximum legibility'),
                value: provider.isBoldText,
                onChanged: (val) {
                  provider.setBoldText(val);
                  AccessibilityScaffold.announce(
                    val ? 'Bold text enabled' : 'Bold text disabled',
                  );
                },
              ),
            ),
            AdiuvaSpacing.gapXl,

            // Visual & Screen Reader Preferences Section
            Text(
              'Visual & Screen Reader Preferences',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,

            // High Contrast Mode Toggle
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('High Contrast Theme', style: theme.textTheme.titleMedium),
                subtitle: const Text('Enhance color contrast for high visibility'),
                value: provider.isHighContrast,
                onChanged: (val) {
                  provider.setHighContrast(val);
                  AccessibilityScaffold.announce(
                    val ? 'High Contrast theme enabled' : 'High Contrast theme disabled',
                  );
                },
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Screen Reader Optimization Toggle
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Screen Reader Optimization', style: theme.textTheme.titleMedium),
                subtitle: const Text('Optimize semantic announcements for TalkBack'),
                value: provider.isScreenReaderOptimized,
                onChanged: (val) {
                  provider.setScreenReaderOptimized(val);
                  AccessibilityScaffold.announce(
                    val ? 'Screen reader optimization enabled' : 'Screen reader optimization disabled',
                  );
                },
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Screen Reader Hints Toggle
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Screen Reader Hints', style: theme.textTheme.titleMedium),
                subtitle: const Text('Speak extra usage hints for buttons and chips'),
                value: provider.screenReaderHints,
                onChanged: (val) {
                  provider.setScreenReaderHints(val);
                },
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Reduced Motion Toggle
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Reduce Motion & Animations', style: theme.textTheme.titleMedium),
                subtitle: const Text('Disable pulsing waveforms and transition effects'),
                value: provider.disableAnimations,
                onChanged: (val) {
                  provider.setDisableAnimations(val);
                  AccessibilityScaffold.announce(
                    val ? 'Reduced motion enabled' : 'Reduced motion disabled',
                  );
                },
              ),
            ),
            AdiuvaSpacing.gapXl,

            // Haptics & Voice Feedback Section
            Text(
              'Haptics & Voice Feedback',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Haptic Feedback Toggle
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Haptic Vibration Feedback', style: theme.textTheme.titleMedium),
                subtitle: const Text('Vibrate device on key interactions and alerts'),
                value: provider.enableHaptics,
                onChanged: (val) {
                  provider.setEnableHaptics(val);
                },
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Auto Voice Feedback Readout Toggle
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Auto Voice Readout', style: theme.textTheme.titleMedium),
                subtitle: const Text('Automatically read OCR and Assistant results aloud'),
                value: provider.enableVoiceFeedback,
                onChanged: (val) {
                  provider.setEnableVoiceFeedback(val);
                },
              ),
            ),
            AdiuvaSpacing.gapXl,
          ],
        ),
      ),
    );
  }

  Widget _buildScaleChip(
    BuildContext context,
    AccessibilityProvider provider,
    double scale,
    String label,
  ) {
    final isSelected = provider.fontScale == scale;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        provider.setFontScale(scale);
        AccessibilityScaffold.announce('Font scale set to $label');
      },
    );
  }
}
