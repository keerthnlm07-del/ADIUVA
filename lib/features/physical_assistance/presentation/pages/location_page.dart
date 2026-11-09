import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../config/routes/app_routes.dart';
import '../provider/physical_assistance_provider.dart';

import '../../../../core/widgets/adiuva_interactive_map_widget.dart';

/// Dedicated ADIUVA Location Screen — Explicit State Rendering & Accessibility Controls
class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  @override
  void initState() {
    super.initState();
    debugPrint('[LOCATION_TRACE] page_opened');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PhysicalAssistanceProvider>();
      if (provider.latitude == null && !provider.isLoadingLocation) {
        provider.fetchCurrentLocation(requestPermissionIfDenied: true);
      }
    });
  }

  String _formatLastUpdated(DateTime? time) {
    if (time == null) return 'Not updated yet';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PhysicalAssistanceProvider>();

    return AccessibilityScaffold(
      pageTitle: 'Location',
      appBar: const CustomAppBar(
        title: 'Your Location',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdiuvaSpacing.gapLg,

            // Interactive Map View
            AdiuvaInteractiveMapWidget(
              latitude: provider.latitude,
              longitude: provider.longitude,
              address: provider.currentAddress,
              onRecenter: () => provider.fetchCurrentLocation(requestPermissionIfDenied: true),
            ),
            AdiuvaSpacing.gapLg,

            // EXPLICIT LOCATION STATE CARDS (A to F)
            _buildLocationStateCard(context, provider),
            AdiuvaSpacing.gapLg,

            // Quick Actions Section
            Text(
              'Location Actions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AdiuvaSpacing.gapSm,

            // Refresh Location Button
            CustomButton.primary(
              label: 'Refresh Current Location',
              leadingIcon: Icons.refresh_rounded,
              onPressed: () => provider.fetchCurrentLocation(requestPermissionIfDenied: true),
            ),
            AdiuvaSpacing.gapMd,

            // Open Maps Search Fallback
            CustomButton.secondary(
              label: 'Search Places on Google Maps',
              leadingIcon: Icons.map_rounded,
              onPressed: () => provider.openGoogleMapsNearbySearch(),
            ),
            AdiuvaSpacing.gapLg,

            // Caregiver Quick Contact Banner
            _buildCaregiverCard(context, provider),
            AdiuvaSpacing.gapXxl,

            // Emergency SOS Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AdiuvaSpacing.minTouchTarget),
                foregroundColor: AdiuvaColors.error,
                side: const BorderSide(color: AdiuvaColors.error, width: 2.0),
              ),
              icon: const Icon(Icons.sos_rounded, color: AdiuvaColors.error),
              label: const Text('EMERGENCY SOS', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.emergencySos);
              },
            ),
            AdiuvaSpacing.gapLg,
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStateCard(BuildContext context, PhysicalAssistanceProvider provider) {
    final theme = Theme.of(context);
    final state = provider.locationState;

    switch (state) {
      // STATE A — LOADING
      case LocationDisplayState.loading:
        return AdiuvaCard(
          backgroundColor: AdiuvaColors.primaryTeal,
          padding: AdiuvaSpacing.paddingLg,
          child: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0),
              ),
              const SizedBox(width: AdiuvaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Getting your location...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Connecting to Android Location Services...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      // STATE C — LOCATION SERVICE OFF
      case LocationDisplayState.serviceDisabled:
        return AdiuvaCard(
          backgroundColor: AdiuvaColors.voiceAmberDark,
          padding: AdiuvaSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.location_off_rounded, color: AdiuvaColors.voiceAmberDark),
                  ),
                  SizedBox(width: AdiuvaSpacing.md),
                  Expanded(
                    child: Text(
                      'Location is turned off.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              AdiuvaSpacing.gapSm,
              const Text(
                'Location services (GPS) are disabled on your device. Please turn on GPS in system settings.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              AdiuvaSpacing.gapMd,
              CustomButton.primary(
                label: 'Open Location Settings',
                leadingIcon: Icons.settings_rounded,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ],
          ),
        );

      // STATE B — PERMISSION REQUIRED
      case LocationDisplayState.permissionDenied:
        return AdiuvaCard(
          backgroundColor: Colors.orange.shade800,
          padding: AdiuvaSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.security_rounded, color: Colors.orange),
                  ),
                  SizedBox(width: AdiuvaSpacing.md),
                  Expanded(
                    child: Text(
                      'Location permission is required.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              AdiuvaSpacing.gapSm,
              const Text(
                'ADIUVA needs location access to determine your current address and navigate safely.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              AdiuvaSpacing.gapMd,
              CustomButton.primary(
                label: 'Allow Location',
                leadingIcon: Icons.check_circle_rounded,
                onPressed: () => provider.fetchCurrentLocation(requestPermissionIfDenied: true),
              ),
            ],
          ),
        );

      // STATE D — PERMISSION PERMANENTLY DENIED
      case LocationDisplayState.permanentlyDenied:
        return AdiuvaCard(
          backgroundColor: AdiuvaColors.error,
          padding: AdiuvaSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.block_rounded, color: AdiuvaColors.error),
                  ),
                  SizedBox(width: AdiuvaSpacing.md),
                  Expanded(
                    child: Text(
                      'Location permission is blocked.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              AdiuvaSpacing.gapSm,
              const Text(
                'Location permission has been permanently denied in Android Settings. Open settings to grant permission.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              AdiuvaSpacing.gapMd,
              CustomButton.primary(
                label: 'Open App Settings',
                leadingIcon: Icons.settings_applications_rounded,
                onPressed: () => provider.openAppSettings(),
              ),
            ],
          ),
        );

      // STATE F — ERROR
      case LocationDisplayState.error:
        return AdiuvaCard(
          backgroundColor: theme.colorScheme.errorContainer,
          padding: AdiuvaSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unable to get your current location.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              AdiuvaSpacing.gapSm,
              Text(
                provider.locationError ?? 'GPS signal error or timeout.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              AdiuvaSpacing.gapMd,
              CustomButton.primary(
                label: 'Try Again',
                leadingIcon: Icons.refresh_rounded,
                onPressed: () => provider.fetchCurrentLocation(requestPermissionIfDenied: true),
              ),
            ],
          ),
        );

      // STATE E — SUCCESS
      case LocationDisplayState.success:
        return AdiuvaCard(
          backgroundColor: AdiuvaColors.primaryTeal,
          padding: AdiuvaSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.my_location_rounded, color: AdiuvaColors.primaryTeal),
                  ),
                  const SizedBox(width: AdiuvaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current GPS Location',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.currentAddress,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                    onPressed: () => provider.fetchCurrentLocation(requestPermissionIfDenied: true),
                    tooltip: 'Refresh Location',
                  ),
                ],
              ),
              const Divider(color: Colors.white30, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latitude: ${provider.latitude!.toStringAsFixed(5)}°',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Longitude: ${provider.longitude!.toStringAsFixed(5)}°',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Accuracy: ${provider.accuracyMeters != null ? provider.accuracyMeters!.toStringAsFixed(1) : "0.0"} m',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Last updated: ${_formatLastUpdated(provider.lastUpdatedTime)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _buildCaregiverCard(BuildContext context, PhysicalAssistanceProvider provider) {
    final theme = Theme.of(context);
    final hasCaregiver = provider.caregiverPhone.trim().isNotEmpty;

    return AdiuvaCard(
      padding: AdiuvaSpacing.paddingMd,
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.phone_rounded, color: Colors.white),
              ),
              const SizedBox(width: AdiuvaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCaregiver ? 'Caregiver: ${provider.caregiverName}' : 'No Caregiver Set',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      hasCaregiver ? provider.caregiverPhone : 'Tap Edit to add caregiver number',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AdiuvaColors.primaryTeal),
                onPressed: () => _showEditCaregiverDialog(context, provider),
                tooltip: 'Edit Caregiver',
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomButton.secondary(
            label: 'Call Caregiver',
            leadingIcon: Icons.phone_in_talk_rounded,
            onPressed: () async {
              final success = await provider.callCaregiver();
              if (!success) {
                AccessibilityScaffold.announce('Please add a caregiver contact in Settings first.');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add a caregiver contact in Settings first.')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditCaregiverDialog(BuildContext context, PhysicalAssistanceProvider provider) {
    final nameCtrl = TextEditingController(text: provider.caregiverName);
    final phoneCtrl = TextEditingController(text: provider.caregiverPhone);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Caregiver Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Caregiver Name',
                hintText: 'e.g. Amma',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Caregiver Phone Number',
                hintText: '+1234567890',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await provider.updateCaregiverInfo(nameCtrl.text, phoneCtrl.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
