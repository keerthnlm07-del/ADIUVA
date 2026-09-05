import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../config/routes/app_routes.dart';
import 'feature_card.dart';

/// Assistive Tools Grid Layout Component
class FeatureGrid extends StatelessWidget {
  final Function(int index)? onNavigateTab;

  const FeatureGrid({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust aspect ratio if text scale factor is large to prevent overflow
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final childAspectRatio = textScale > 1.2 ? 1.1 : 1.35;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AdiuvaSpacing.md,
          mainAxisSpacing: AdiuvaSpacing.md,
          childAspectRatio: childAspectRatio,
          children: [
            FeatureCard(
              title: 'Vision',
              subtitle: 'Describe objects & surroundings',
              icon: Icons.remove_red_eye_outlined,
              iconColor: AdiuvaColors.primaryTeal,
              onTap: () {
                if (onNavigateTab != null) {
                  onNavigateTab!(2); // Switch to Vision tab
                } else {
                  Navigator.of(context).pushNamed(AppRoutes.vision);
                }
              },
            ),
            FeatureCard(
              title: 'Read Text',
              subtitle: 'Read signs & documents aloud',
              icon: Icons.document_scanner_outlined,
              iconColor: AdiuvaColors.primaryLight,
              onTap: () {
                if (onNavigateTab != null) {
                  onNavigateTab!(2); // Switch to Vision tab
                } else {
                  Navigator.of(context).pushNamed(AppRoutes.vision);
                }
              },
            ),
            FeatureCard(
              title: 'Scan Code',
              subtitle: 'Barcodes & QR codes',
              icon: Icons.qr_code_scanner_rounded,
              iconColor: const Color(0xFF0284C7), // Sky 600
              onTap: () {
                if (onNavigateTab != null) {
                  onNavigateTab!(2); // Switch to Vision tab
                } else {
                  Navigator.of(context).pushNamed(AppRoutes.vision);
                }
              },
            ),
            FeatureCard(
              title: 'Navigate',
              subtitle: 'Direction & obstacle assistant',
              icon: Icons.explore_outlined,
              iconColor: AdiuvaColors.voiceAmberDark,
              onTap: () {
                if (onNavigateTab != null) {
                  onNavigateTab!(3); // Switch to Navigate tab
                } else {
                  Navigator.of(context).pushNamed(AppRoutes.navigate);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
