import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../config/routes/app_routes.dart';
import '../widgets/home_header.dart';
import '../widgets/feature_grid.dart';

/// ADIUVA Home Dashboard Page
class HomePage extends StatelessWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomePage({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Greeting, User Name, Avatar, Status Badge
          const HomeHeader(),
          AdiuvaSpacing.gapXl,

          // Primary "Talk to ADIUVA" Action Button (Sand/Amber mode)
          CustomButton.voiceAction(
            label: 'Talk to ADIUVA',
            leadingIcon: Icons.mic_none_outlined,
            semanticHint: 'Double tap to open Voice Assistant Mode',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.voiceMode);
            },
          ),
          AdiuvaSpacing.gapXl,

          // Assistive Tools Section Title
          Text(
            'Assistive Tools',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AdiuvaSpacing.gapMd,

          // Feature Grid (Vision, Read Text, Scan Code, Navigate)
          FeatureGrid(onNavigateTab: onNavigateTab),
          AdiuvaSpacing.gapXl,

          // Recent Activity Section (Clean Empty State as per spec)
          Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AdiuvaSpacing.gapMd,
          AdiuvaCard(
            padding: AdiuvaSpacing.paddingLg,
            child: Row(
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 28,
                ),
                const SizedBox(width: AdiuvaSpacing.md),
                Expanded(
                  child: Text(
                    'No recent activity yet. Your quick actions and assistant history will appear here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AdiuvaSpacing.gapXxl,

          // Emergency Help Action Entry Point
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AdiuvaSpacing.minTouchTarget),
              foregroundColor: AdiuvaColors.error,
              side: const BorderSide(color: AdiuvaColors.error, width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.sos_rounded, color: AdiuvaColors.error, size: 28),
            label: const Text(
              'EMERGENCY HELP',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.emergencySos);
            },
          ),
          AdiuvaSpacing.gapXl,
        ],
      ),
    );
  }
}
