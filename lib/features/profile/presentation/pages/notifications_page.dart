import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../accessibility/presentation/provider/accessibility_provider.dart';

/// ADIUVA Notifications Settings Page
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AccessibilityProvider>(context);

    return AccessibilityScaffold(
      pageTitle: 'Notification Settings',
      appBar: const CustomAppBar(title: 'Notifications'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Alerts & Notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Push Notifications', style: theme.textTheme.titleMedium),
                subtitle: const Text('Receive announcements and updates'),
                value: provider.pushNotificationsEnabled,
                onChanged: (val) => provider.setPushNotifications(val),
              ),
            ),
            AdiuvaSpacing.gapMd,
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Emergency Alerts', style: theme.textTheme.titleMedium),
                subtitle: const Text('High priority notifications for emergency help'),
                value: provider.emergencyAlertsEnabled,
                onChanged: (val) => provider.setEmergencyAlerts(val),
              ),
            ),
            AdiuvaSpacing.gapXl,
          ],
        ),
      ),
    );
  }
}
