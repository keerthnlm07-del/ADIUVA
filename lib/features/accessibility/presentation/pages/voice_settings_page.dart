import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../provider/accessibility_provider.dart';

/// ADIUVA Voice & Speech Settings Page
class VoiceSettingsPage extends StatelessWidget {
  const VoiceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AccessibilityProvider>(context);

    return AccessibilityScaffold(
      pageTitle: 'Voice & Speech Settings',
      appBar: const CustomAppBar(title: 'Voice & Speech Settings'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text-to-Speech Controls',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Speech Speed / Rate Slider
            AdiuvaCard(
              padding: AdiuvaSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Speech Speed (Rate)', style: theme.textTheme.titleMedium),
                      Text('${provider.speechRate.toStringAsFixed(2)}x', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: provider.speechRate,
                    min: 0.25,
                    max: 1.5,
                    divisions: 10,
                    label: '${provider.speechRate.toStringAsFixed(2)}x',
                    onChanged: (val) {
                      provider.setSpeechRate(val);
                    },
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Speech Pitch Slider
            AdiuvaCard(
              padding: AdiuvaSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Voice Pitch', style: theme.textTheme.titleMedium),
                      Text(provider.speechPitch.toStringAsFixed(2), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: provider.speechPitch,
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                    label: provider.speechPitch.toStringAsFixed(2),
                    onChanged: (val) {
                      provider.setSpeechPitch(val);
                    },
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Speech Volume Slider
            AdiuvaCard(
              padding: AdiuvaSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Voice Volume', style: theme.textTheme.titleMedium),
                      Text('${(provider.speechVolume * 100).toInt()}%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: provider.speechVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(provider.speechVolume * 100).toInt()}%',
                    onChanged: (val) {
                      provider.setSpeechVolume(val);
                    },
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapXl,

            // Auto-Read Settings Toggle
            Text(
              'Automated Voice Behaviors',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Auto-Read Assistant Responses', style: theme.textTheme.titleMedium),
                subtitle: const Text('Automatically speak AI Assistant answers upon completion'),
                value: provider.enableVoiceFeedback,
                onChanged: (val) {
                  provider.setEnableVoiceFeedback(val);
                },
              ),
            ),
            AdiuvaSpacing.gapXl,

            // Preview Voice Button
            CustomButton.primary(
              label: 'Preview Voice Output',
              leadingIcon: Icons.volume_up_outlined,
              onPressed: () => provider.testSpeech(),
            ),
            AdiuvaSpacing.gapXl,
          ],
        ),
      ),
    );
  }
}
