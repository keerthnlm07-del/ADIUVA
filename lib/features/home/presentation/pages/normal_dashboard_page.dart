import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_icon_tile.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../visual_assistance/presentation/provider/visual_assistance_provider.dart';
import '../../../visual_assistance/domain/entities/vision_result.dart';

/// Personalized Normal User Accessibility Suite Dashboard — Icon-First Design
class NormalDashboardPage extends StatelessWidget {
  const NormalDashboardPage({super.key});

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
        'title': 'Visual Tools',
        'icon': Icons.camera_alt_rounded,
        'color': AdiuvaColors.primaryTeal,
        'action': () => _openVisionMode(context, VisionMode.describeScene, 'Visual Tools'),
      },
      {
        'title': 'OCR & Text',
        'icon': Icons.document_scanner_rounded,
        'color': Colors.indigo,
        'action': () => _openVisionMode(context, VisionMode.readText, 'OCR Text Reader'),
      },
      {
        'title': 'Translator',
        'icon': Icons.translate_rounded,
        'color': Colors.blue,
        'action': () => Navigator.of(context).pushNamed(AppRoutes.translator),
      },
      {
        'title': 'Sign Language',
        'icon': Icons.sign_language_rounded,
        'color': Colors.purple,
        'action': () => Navigator.of(context).pushNamed(AppRoutes.signLanguage),
      },
      {
        'title': 'Notes & Memory',
        'icon': Icons.note_alt_rounded,
        'color': Colors.deepOrange,
        'action': () => Navigator.of(context).pushNamed(AppRoutes.notes),
      },
      {
        'title': 'Speech Assistant',
        'icon': Icons.mic_rounded,
        'color': AdiuvaColors.voiceAmberDark,
        'action': () => Navigator.of(context).pushNamed(AppRoutes.voiceMode),
      },
      {
        'title': 'Emergency SOS',
        'icon': Icons.sos_rounded,
        'color': AdiuvaColors.error,
        'action': () => Navigator.of(context).pushNamed(AppRoutes.emergencySos),
      },
    ];

    return AccessibilityScaffold(
      pageTitle: 'Normal User Suite',
      appBar: const CustomAppBar(
        title: 'Universal Suite',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdiuvaSpacing.gapLg,
            Text(
              'Universal Utilities',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AdiuvaSpacing.gapXs,
            Text(
              'Select an accessibility tool:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AdiuvaSpacing.gapLg,

            // 2-Column Icon Grid
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

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
