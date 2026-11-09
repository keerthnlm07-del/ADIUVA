import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_icon_tile.dart';
import '../../../../config/routes/app_routes.dart';
import '../provider/visual_assistance_provider.dart';
import '../../domain/entities/vision_result.dart';

/// Personalized Blind / Visual Assistance Dashboard — Icon-First Design
class BlindDashboardPage extends StatelessWidget {
  const BlindDashboardPage({super.key});

  void _openVisionMode(BuildContext context, VisionMode mode, String label) {
    try {
      final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
      visionProvider.setVisionMode(mode);
    } catch (_) {}
    Navigator.of(context).pushNamed(AppRoutes.vision);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Object Detection',
        'icon': Icons.view_in_ar_rounded,
        'color': AdiuvaColors.primaryTeal,
        'action': () => _openVisionMode(context, VisionMode.identifyObject, 'Object Detection'),
      },
      {
        'title': 'Read Text / OCR',
        'icon': Icons.document_scanner_rounded,
        'color': Colors.indigo,
        'action': () => _openVisionMode(context, VisionMode.readText, 'Text Reader'),
      },
      {
        'title': 'Scene Description',
        'icon': Icons.photo_camera_rounded,
        'color': Colors.teal,
        'action': () => _openVisionMode(context, VisionMode.describeScene, 'Scene Description'),
      },
      {
        'title': 'Voice Assistant',
        'icon': Icons.mic_rounded,
        'color': AdiuvaColors.voiceAmberDark,
        'action': () => Navigator.of(context).pushNamed(AppRoutes.voiceMode),
      },
      {
        'title': 'Translator',
        'icon': Icons.translate_rounded,
        'color': Colors.blue,
        'action': () => Navigator.of(context).pushNamed(AppRoutes.translator),
      },
    ];

    return AccessibilityScaffold(
      pageTitle: 'Blind & Visual Assistance',
      appBar: const CustomAppBar(
        title: 'Visual Assistance',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdiuvaSpacing.gapLg,
            Text(
              'Visual Tools',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AdiuvaSpacing.gapXs,
            Text(
              'Select an assistive vision tool:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AdiuvaSpacing.gapLg,

            // 2-Column Icon Grid for Visual Tools
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
                  onTap: item['action'] as VoidCallback,
                );
              },
            ),

            AdiuvaSpacing.gapLg,

            // SOS Emergency Module
            AdiuvaIconTile(
              title: 'Emergency SOS',
              subtitle: 'Broadcast alert & call 112',
              icon: Icons.sos_rounded,
              color: AdiuvaColors.error,
              semanticLabel: 'Open Emergency SOS',
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.emergencySos);
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
