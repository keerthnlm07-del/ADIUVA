import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';

/// ADIUVA Device Permissions Management Page
class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _micStatus = PermissionStatus.denied;
  PermissionStatus _locationStatus = PermissionStatus.denied;
  PermissionStatus _notificationStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkStatuses();
  }

  Future<void> _checkStatuses() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    final loc = await Permission.locationWhenInUse.status;
    final notif = await Permission.notification.status;

    setState(() {
      _cameraStatus = cam;
      _micStatus = mic;
      _locationStatus = loc;
      _notificationStatus = notif;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    await permission.request();
    await _checkStatuses();
  }

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required IconData icon,
    required PermissionStatus status,
    required Permission permission,
  }) {
    final theme = Theme.of(context);
    final isGranted = status.isGranted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AdiuvaSpacing.md),
      child: AdiuvaCard(
        padding: AdiuvaSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: isGranted ? AdiuvaColors.primaryTeal : AdiuvaColors.slate600),
                    const SizedBox(width: 8),
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Chip(
                  label: Text(isGranted ? 'Granted' : 'Not Granted'),
                  backgroundColor: isGranted ? AdiuvaColors.primaryContainer : theme.colorScheme.errorContainer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (!isGranted)
              Row(
                children: [
                  CustomButton.secondary(
                    label: 'Allow',
                    onPressed: () => _requestPermission(permission),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AccessibilityScaffold(
      pageTitle: 'Permissions Management',
      appBar: const CustomAppBar(title: 'App Permissions'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hardware & System Access Control',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Camera
            _buildPermissionTile(
              title: 'Camera Access',
              description: 'Required for scene description, OCR text extraction, object identification, and QR/barcode scanning.',
              icon: Icons.camera_alt_outlined,
              status: _cameraStatus,
              permission: Permission.camera,
            ),

            // Microphone
            _buildPermissionTile(
              title: 'Microphone Access',
              description: 'Required for Voice Assistant speech recognition.',
              icon: Icons.mic_none_outlined,
              status: _micStatus,
              permission: Permission.microphone,
            ),

            // Location
            _buildPermissionTile(
              title: 'Location Access',
              description: 'Required for outdoor navigation and obstacle alerts.',
              icon: Icons.location_on_outlined,
              status: _locationStatus,
              permission: Permission.locationWhenInUse,
            ),

            // Notifications
            _buildPermissionTile(
              title: 'Notifications Access',
              description: 'Required for emergency alerts and voice guidance reminders.',
              icon: Icons.notifications_none_outlined,
              status: _notificationStatus,
              permission: Permission.notification,
            ),
            AdiuvaSpacing.gapXl,

            // Open System Settings Action
            CustomButton.primary(
              label: 'Open System App Settings',
              leadingIcon: Icons.settings_outlined,
              onPressed: () async {
                await openAppSettings();
                await _checkStatuses();
              },
            ),
            AdiuvaSpacing.gapXl,
          ],
        ),
      ),
    );
  }
}
