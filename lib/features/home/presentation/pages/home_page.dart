import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/adiuva_icon_tile.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../widgets/home_header.dart';

/// ADIUVA Main Home Dashboard Page
/// 
/// Contains EXACTLY the 5 Primary User Mode Options:
/// 1. Blind / Visual Assistance
/// 2. Deaf / Hearing Assistance
/// 3. Cognitive Assistance
/// 4. Physical Assistance
/// 5. Normal User
class HomePage extends StatelessWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomePage({
    super.key,
    this.onNavigateTab,
  });

  static const List<Map<String, dynamic>> _modeCards = [
    {
      'id': 'blind',
      'title': 'Blind Assistance',
      'subtitle': 'Visual & Voice Tools',
      'icon': Icons.visibility_rounded,
      'color': AdiuvaColors.primaryTeal,
      'route': AppRoutes.blindMode,
    },
    {
      'id': 'deaf',
      'title': 'Hearing Assistance',
      'subtitle': 'Captions & Alerts',
      'icon': Icons.hearing_rounded,
      'color': Colors.blue,
      'route': AppRoutes.hearingAssistance,
    },
    {
      'id': 'cognitive',
      'title': 'Cognitive Assistance',
      'subtitle': 'Routines & Memory',
      'icon': Icons.psychology_rounded,
      'color': Colors.purple,
      'route': AppRoutes.cognitiveAssistance,
    },
    {
      'id': 'physical',
      'title': 'Physical Assistance',
      'subtitle': 'Motor Control & Calls',
      'icon': Icons.accessible_forward_rounded,
      'color': Colors.teal,
      'route': AppRoutes.physicalAssistance,
    },
    {
      'id': 'normal',
      'title': 'Normal User',
      'subtitle': 'Universal Suite',
      'icon': Icons.person_rounded,
      'color': AdiuvaColors.voiceAmberDark,
      'route': AppRoutes.normalUser,
    },
  ];

  @override
  Widget build(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      debugPrint('[AUTH_TRACE] home_entered uid=${authProvider.user?.userId}');
    } catch (_) {}

    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Greeting, User Name, Avatar, Status Badge
          const HomeHeader(),
          AdiuvaSpacing.gapLg,

          // Section Title
          Text(
            'Assistance Modes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AdiuvaSpacing.gapXs,
          Text(
            'Select your assistance mode:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AdiuvaSpacing.gapLg,

          // 2-Column Responsive Icon Grid for 5 Primary Modes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _modeCards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AdiuvaSpacing.md,
              mainAxisSpacing: AdiuvaSpacing.md,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final mode = _modeCards[index];
              return AdiuvaIconTile(
                title: mode['title'] as String,
                subtitle: mode['subtitle'] as String?,
                icon: mode['icon'] as IconData,
                color: mode['color'] as Color,
                semanticLabel: 'Open ${mode['title']}',
                onTap: () {
                  Navigator.of(context).pushNamed(mode['route'] as String);
                },
              );
            },
          ),

          AdiuvaSpacing.gapXl,

          // Emergency SOS Bar (Red Emergency Control)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AdiuvaSpacing.minTouchTarget),
              foregroundColor: AdiuvaColors.error,
              side: const BorderSide(color: AdiuvaColors.error, width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.sos_rounded, color: AdiuvaColors.error, size: 28),
            label: const Text(
              'EMERGENCY SOS',
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

          // Bottom padding to ensure GlobalVoiceFab never covers controls
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
