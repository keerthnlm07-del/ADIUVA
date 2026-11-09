import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_icon_tile.dart';
import '../../../../config/routes/app_routes.dart';

/// ADIUVA Cognitive Assistance Dashboard — Icon-First Design
class CognitiveAssistancePage extends StatelessWidget {
  const CognitiveAssistancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Daily Tasks',
        'icon': Icons.checklist_rounded,
        'color': AdiuvaColors.primaryTeal,
        'route': AppRoutes.todoList,
      },
      {
        'title': 'Reminders',
        'icon': Icons.alarm_rounded,
        'color': AdiuvaColors.voiceAmberDark,
        'route': AppRoutes.reminders,
        'arguments': {'tab': 0}, // Reminders & Medication inside
      },
      {
        'title': 'Calendar',
        'icon': Icons.calendar_today_rounded,
        'color': Colors.deepPurple,
        'route': AppRoutes.reminders,
        'arguments': {'tab': 2}, // Calendar view tab
      },
      {
        'title': 'Notes',
        'icon': Icons.note_alt_rounded,
        'color': Colors.indigo,
        'route': AppRoutes.notes,
      },
      {
        'title': 'SOS',
        'icon': Icons.sos_rounded,
        'color': AdiuvaColors.error,
        'route': AppRoutes.emergencySos,
      },
    ];

    return AccessibilityScaffold(
      pageTitle: 'Cognitive Assistance',
      appBar: const CustomAppBar(
        title: 'Cognitive Helper',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdiuvaSpacing.gapLg,
            Text(
              'Routines & Memory',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            AdiuvaSpacing.gapSm,
            Text(
              'Select a memory or routine tool:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AdiuvaSpacing.gapLg,

            // 2-Column Icon-First Grid
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
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      item['route'] as String,
                      arguments: item['arguments'],
                    );
                  },
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
