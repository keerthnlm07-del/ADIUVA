import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../config/routes/app_routes.dart';

/// ADIUVA 5-Mode User Selection Page
class DisabilitySelectionPage extends StatelessWidget {
  const DisabilitySelectionPage({super.key});

  static const List<Map<String, dynamic>> _modes = [
    {
      'id': 'blind',
      'title': 'Blind / Visually Impaired',
      'description': 'Voice-first guidance, object detection, text reading, and high contrast.',
      'icon': Icons.visibility_off_rounded,
      'route': AppRoutes.vision,
      'color': AdiuvaColors.primaryTeal,
    },
    {
      'id': 'deaf',
      'title': 'Deaf / Hard of Hearing',
      'description': 'Real-time live captioning, sound alerts, visual indicators, and sign language.',
      'icon': Icons.hearing_disabled_rounded,
      'route': AppRoutes.hearingAssistance,
      'color': Colors.blue,
    },
    {
      'id': 'cognitive',
      'title': 'Cognitive Assistance',
      'description': 'Step-by-step guidance, reminders, memory notes, and simple daily tasks.',
      'icon': Icons.psychology_rounded,
      'route': AppRoutes.cognitiveAssistance,
      'color': Colors.purple,
    },
    {
      'id': 'physical',
      'title': 'Physical / Motor Assistance',
      'description': 'Large touch targets, voice shortcuts, quick emergency dialing, and navigation.',
      'icon': Icons.accessible_forward_rounded,
      'route': AppRoutes.physicalAssistance,
      'color': Colors.teal,
    },
    {
      'id': 'normal',
      'title': 'Normal User',
      'description': 'Universal assistive utilities, smart AI assistant, travel guide, and quick tools.',
      'icon': Icons.person_rounded,
      'route': AppRoutes.home,
      'color': AdiuvaColors.voiceAmberDark,
    },
  ];

  void _selectMode(BuildContext context, Map<String, dynamic> mode) {
    AccessibilityScaffold.announce('Selected ${mode['title']}. Opening dashboard.');
    Navigator.of(context).pushReplacementNamed(mode['route'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AccessibilityScaffold(
      pageTitle: 'Assistance Mode Selection',
      appBar: const CustomAppBar(
        title: 'Choose Mode',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdiuvaSpacing.gapLg,
            Text(
              'Select Your Preferred Experience',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            AdiuvaSpacing.gapSm,
            Text(
              'You can switch modes anytime or say "Switch to Visual Mode", "Open Hearing", etc.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AdiuvaSpacing.gapLg,

            ..._modes.map((mode) {
              final color = mode['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(bottom: AdiuvaSpacing.md),
                child: InkWell(
                  onTap: () => _selectMode(context, mode),
                  borderRadius: BorderRadius.circular(16),
                  child: AdiuvaCard(
                    padding: AdiuvaSpacing.paddingLg,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(mode['icon'] as IconData, color: color, size: 28),
                        ),
                        const SizedBox(width: AdiuvaSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode['title'] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mode['description'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 28),
                      ],
                    ),
                  ),
                ),
              );
            }),

            AdiuvaSpacing.gapLg,
          ],
        ),
      ),
    );
  }
}
