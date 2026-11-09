import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_icon_tile.dart';
import '../../../../config/routes/app_routes.dart';
import '../provider/physical_assistance_provider.dart';

/// ADIUVA Physical Assistance Dashboard — Icon-First Motor-Accessible Design
class PhysicalAssistancePage extends StatelessWidget {
  const PhysicalAssistancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PhysicalAssistanceProvider>();

    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Location',
        'icon': Icons.my_location_rounded,
        'color': Colors.blue,
        'action': () {
          Navigator.of(context).pushNamed(AppRoutes.location);
        },
      },
      {
        'title': 'Call Caregiver',
        'icon': Icons.phone_in_talk_rounded,
        'color': Colors.green,
        'action': () async {
          final success = await provider.callCaregiver();
          if (!success) {
            AccessibilityScaffold.announce('Unable to launch phone call to ${provider.caregiverPhone}');
          }
        },
      },
      {
        'title': 'Home',
        'icon': Icons.home_rounded,
        'color': AdiuvaColors.slate700,
        'action': () {
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
        },
      },
      {
        'title': 'SOS',
        'icon': Icons.sos_rounded,
        'color': AdiuvaColors.error,
        'action': () {
          Navigator.of(context).pushNamed(AppRoutes.emergencySos);
        },
      },
    ];

    return AccessibilityScaffold(
      pageTitle: 'Physical Assistance',
      appBar: const CustomAppBar(
        title: 'Physical Helper',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdiuvaSpacing.gapLg,
            Text(
              'Physical Controls',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            AdiuvaSpacing.gapSm,
            Text(
              'Large icon controls optimized for motor accessibility:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AdiuvaSpacing.gapLg,

            // 2-Column Icon Grid with Generous Touch Targets
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AdiuvaSpacing.md,
                mainAxisSpacing: AdiuvaSpacing.md,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final item = modules[index];
                return AdiuvaIconTile(
                  title: item['title'] as String,
                  icon: item['icon'] as IconData,
                  color: item['color'] as Color,
                  minHeight: 88,
                  onTap: item['action'] as VoidCallback,
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
