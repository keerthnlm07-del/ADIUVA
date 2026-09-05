import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../auth/presentation/provider/auth_provider.dart';

/// ADIUVA Home Header Component
/// 
/// Features:
/// - Dynamic time-of-day greeting (Good Morning / Afternoon / Evening)
/// - Authenticated user display name
/// - Accessible profile avatar action (56dp touch target)
/// - Accessibility mode status indicator chip
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name.trim();
    final displayName = (userName != null && userName.isNotEmpty) ? userName : 'Friend';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AdiuvaSpacing.md),
            // Accessible Profile Avatar Action Button (56dp hit area)
            Semantics(
              label: 'View Profile for $displayName',
              button: true,
              child: SizedBox(
                width: AdiuvaSpacing.minTouchTarget,
                height: AdiuvaSpacing.minTouchTarget,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.profile);
                  },
                  icon: CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        AdiuvaSpacing.gapMd,
        // Status indicator chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AdiuvaColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AdiuvaColors.primaryTeal.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AdiuvaColors.primaryTeal,
              ),
              const SizedBox(width: 6),
              Text(
                'ADIUVA Accessibility Active',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AdiuvaColors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
