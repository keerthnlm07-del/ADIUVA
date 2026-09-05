import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../accessibility/presentation/provider/accessibility_provider.dart';

/// ADIUVA Privacy & Data Settings Page
class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  void _confirmClearData(BuildContext context, AccessibilityProvider provider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Saved App Settings?'),
          content: const Text('This will reset your local preferences and clear cached data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdiuvaColors.error),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                provider.clearAllSettings();
                AccessibilityScaffold.announce('All settings reset to default');
              },
              child: const Text('Clear Data', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AccessibilityProvider>(context);

    return AccessibilityScaffold(
      pageTitle: 'Privacy & Data Protection',
      appBar: const CustomAppBar(title: 'Privacy Settings'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Protections',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,
            AdiuvaCard(
              padding: AdiuvaSpacing.paddingLg,
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AdiuvaColors.primaryTeal, size: 32),
                  const SizedBox(width: AdiuvaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Local Processing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Camera feeds and speech input are processed strictly for live accessibility assistance.', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapXl,

            Text(
              'Local Storage & Cache',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,

            CustomButton.outlined(
              label: 'Clear Saved Settings & Cache',
              leadingIcon: Icons.delete_outline_rounded,
              onPressed: () => _confirmClearData(context, provider),
            ),
            AdiuvaSpacing.gapXl,
          ],
        ),
      ),
    );
  }
}
