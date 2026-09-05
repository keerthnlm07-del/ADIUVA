import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../auth/presentation/provider/auth_provider.dart';

/// ADIUVA Profile & Settings Hub Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AdiuvaSpacing.md),
      child: AdiuvaCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        semanticLabel: '$title. $subtitle',
        semanticHint: 'Double tap to open $title',
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveIconColor, size: 24),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?.name.trim() ?? 'User';
    final userEmail = user?.email ?? 'No email provided';
    final userType = user?.userType.replaceAll('_', ' ').toUpperCase() ?? 'ACCESSIBILITY USER';

    return AccessibilityScaffold(
      pageTitle: 'Profile & Settings',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header Card
            AdiuvaCard(
              padding: AdiuvaSpacing.paddingLg,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AdiuvaSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userType,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapXl,

            // Emergency Contacts Section
            Text(
              'Emergency & Safety',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AdiuvaSpacing.gapMd,
            _buildSettingsTile(
              context: context,
              icon: Icons.contact_emergency_rounded,
              iconColor: AdiuvaColors.error,
              title: 'Emergency Contacts & SOS Setup',
              subtitle: 'Manage family/trusted contacts for emergency alerts',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.emergencyContacts),
            ),
            AdiuvaSpacing.gapXl,

            // Settings Section Title
            Text(
              'App & Accessibility Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Settings Navigation Options
            _buildSettingsTile(
              context: context,
              icon: Icons.accessibility_new_rounded,
              title: 'Accessibility Settings',
              subtitle: 'Contrast, text scale, animations & haptics',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.accessibilitySettings),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.record_voice_over_outlined,
              title: 'Voice & Speech Settings',
              subtitle: 'TTS speech rate, pitch & volume controls',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.voiceSettings),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.language_rounded,
              title: 'Language Settings',
              subtitle: 'Application and speech recognition language',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.languageSettings),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.palette_outlined,
              title: 'Appearance Settings',
              subtitle: 'System, Light, Dark & High Contrast themes',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.appearanceSettings),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Push alerts & emergency notifications',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & Storage',
              subtitle: 'Data processing policy & cache management',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacySettings),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.security_rounded,
              title: 'Permissions Management',
              subtitle: 'Camera, Microphone & System permissions',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacySettings),
            ),
            AdiuvaSpacing.gapXl,

            // Sign Out Button
            CustomButton.outlined(
              label: 'Sign Out',
              leadingIcon: Icons.logout_rounded,
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
            ),
            AdiuvaSpacing.gapXxl,
          ],
        ),
      ),
    );
  }
}
