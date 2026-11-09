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
import '../../../physical_assistance/presentation/provider/physical_assistance_provider.dart';

import '../../../../core/widgets/adiuva_interactive_map_widget.dart';

/// ADIUVA GPS Navigation & Location Helper Page — Explicit Rendering
class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  String _selectedTransportFilter = 'all'; // 'all', 'bus', 'train'
  bool _hasProcessedArgs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PhysicalAssistanceProvider>();
      if (provider.latitude == null && !provider.isLoadingLocation) {
        provider.fetchCurrentLocation(requestPermissionIfDenied: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasProcessedArgs) return;
    _hasProcessedArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      if (args['filter'] == 'transport' || args['filter'] == 'bus') {
        _selectedTransportFilter = 'bus';
      } else if (args['filter'] == 'train') {
        _selectedTransportFilter = 'train';
      } else if (args['filter'] == 'location') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<PhysicalAssistanceProvider>().fetchCurrentLocation(requestPermissionIfDenied: true);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PhysicalAssistanceProvider>();

    return AccessibilityScaffold(
      pageTitle: 'Location & GPS Navigation',
      appBar: const CustomAppBar(
        title: 'Location & Navigation',
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

            // 1. Current Location Section Header & Card
            _buildCurrentLocationSection(context, provider),
            AdiuvaSpacing.gapLg,

            // 2. Transport Filter Control (All, Bus, Train)
            Text(
              'Transport & Nearby Filter',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AdiuvaSpacing.gapSm,
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('All Places'),
                    selected: _selectedTransportFilter == 'all',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTransportFilter = 'all');
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.directions_bus_rounded, size: 16),
                    label: const Text('Bus Stops'),
                    selected: _selectedTransportFilter == 'bus',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTransportFilter = 'bus');
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.train_rounded, size: 16),
                    label: const Text('Train Stations'),
                    selected: _selectedTransportFilter == 'train',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTransportFilter = 'train');
                    },
                  ),
                ),
              ],
            ),
            AdiuvaSpacing.gapLg,

            // 3. Nearby Section (~100m Search Radius & Explicit Fallback)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTransportFilter == 'bus'
                      ? 'Nearby Bus Stops (~100m)'
                      : (_selectedTransportFilter == 'train'
                          ? 'Nearby Train Stations (~100m)'
                          : 'Nearby Places (~100m)'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdiuvaColors.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Radius: 100m',
                    style: TextStyle(color: AdiuvaColors.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            AdiuvaSpacing.gapSm,

            // Explicit Fallback Card (No Fabricated POIs)
            AdiuvaCard(
              padding: AdiuvaSpacing.paddingLg,
              child: Column(
                children: [
                  const Icon(Icons.location_searching_rounded, color: AdiuvaColors.primaryTeal, size: 40),
                  AdiuvaSpacing.gapSm,
                  Text(
                    _selectedTransportFilter == 'bus'
                        ? 'Nearby bus stop data is unavailable in ADIUVA right now.'
                        : (_selectedTransportFilter == 'train'
                            ? 'Nearby train station data is unavailable in ADIUVA right now.'
                            : 'Nearby place data is unavailable in ADIUVA right now.'),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  AdiuvaSpacing.gapSm,
                  Text(
                    'No live Places API is currently connected. You can search directly on Google Maps.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  AdiuvaSpacing.gapMd,
                  CustomButton.primary(
                    label: _selectedTransportFilter == 'bus'
                        ? 'Search Bus Stops in Google Maps'
                        : (_selectedTransportFilter == 'train'
                            ? 'Search Train Stations in Google Maps'
                            : 'Search Nearby Places in Google Maps'),
                    leadingIcon: Icons.map_rounded,
                    onPressed: () {
                      final query = _selectedTransportFilter == 'bus'
                          ? 'bus stop near me'
                          : (_selectedTransportFilter == 'train'
                              ? 'train station near me'
                              : 'places near me');
                      provider.openGoogleMapsNearbySearch(query: query);
                    },
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapLg,

            // 4. Caregiver Banner
            _buildCaregiverBanner(context, provider),
            AdiuvaSpacing.gapXxl,

            // 5. Emergency SOS Button
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

  Widget _buildCurrentLocationSection(BuildContext context, PhysicalAssistanceProvider provider) {
    final state = provider.locationState;

    switch (state) {
      case LocationDisplayState.loading:
        return AdiuvaCard(
          backgroundColor: AdiuvaColors.primaryTeal,
          padding: AdiuvaSpacing.paddingLg,
          child: Row(
            children: const [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)),
              SizedBox(width: 12),
              Text('Obtaining GPS position...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        );

      case LocationDisplayState.serviceDisabled:
        return AdiuvaCard(
          backgroundColor: AdiuvaColors.voiceAmberDark,
          padding: AdiuvaSpacing.paddingMd,
          child: Row(
            children: [
              const Icon(Icons.location_off_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Location is turned off.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              TextButton(
                onPressed: () => Geolocator.openLocationSettings(),
                child: const Text('Turn On', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

      case LocationDisplayState.permissionDenied:
      case LocationDisplayState.permanentlyDenied:
        return AdiuvaCard(
          backgroundColor: Colors.orange.shade800,
          padding: AdiuvaSpacing.paddingMd,
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Location permission required.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              TextButton(
                onPressed: () => provider.fetchCurrentLocation(requestPermissionIfDenied: true),
                child: const Text('Allow', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

      case LocationDisplayState.error:
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
                          'Current Location',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          provider.currentAddress,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                    onPressed: () => provider.fetchCurrentLocation(requestPermissionIfDenied: true),
                  ),
                ],
              ),
              if (provider.latitude != null && provider.longitude != null) ...[
                const Divider(color: Colors.white30, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lat: ${provider.latitude!.toStringAsFixed(5)}, Lng: ${provider.longitude!.toStringAsFixed(5)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      'Accuracy: ${provider.accuracyMeters != null ? provider.accuracyMeters!.toStringAsFixed(1) : "0.0"}m',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildCaregiverBanner(BuildContext context, PhysicalAssistanceProvider provider) {
    final theme = Theme.of(context);
    final hasCaregiver = provider.caregiverPhone.trim().isNotEmpty;

    return AdiuvaCard(
      padding: AdiuvaSpacing.paddingMd,
      child: Row(
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
                Text(hasCaregiver ? 'Caregiver: ${provider.caregiverName}' : 'No Caregiver Set', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(hasCaregiver ? provider.caregiverPhone : 'Tap to add caregiver', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.callCaregiver();
              if (!success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add a caregiver contact in Settings first.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Call Caregiver'),
          ),
        ],
      ),
    );
  }
}
