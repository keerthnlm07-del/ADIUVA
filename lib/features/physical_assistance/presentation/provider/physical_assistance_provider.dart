import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/local_storage_service.dart';

class NearbyPoi {
  final String name;
  final double distanceMeters;
  final String category; // 'transport', 'medical', 'general'
  final double latitude;
  final double longitude;

  NearbyPoi({
    required this.name,
    required this.distanceMeters,
    required this.category,
    required this.latitude,
    required this.longitude,
  });
}

enum LocationDisplayState {
  loading,
  serviceDisabled,
  permissionDenied,
  permanentlyDenied,
  success,
  error,
}

class PhysicalAssistanceProvider extends ChangeNotifier {
  final LocalStorageService _storageService;
  static const String _caregiverNameKey = 'adiuva_caregiver_name';
  static const String _caregiverPhoneKey = 'adiuva_caregiver_phone';

  double? _latitude;
  double? _longitude;
  double? _accuracyMeters;
  DateTime? _lastUpdatedTime;
  String _currentAddress = 'Location not fetched yet';
  bool _isLoadingLocation = false;
  bool _isLocationServiceDisabled = false;
  bool _isPermissionDenied = false;
  bool _isPermanentlyDenied = false;
  String? _locationError;

  String _caregiverName = '';
  String _caregiverPhone = '';

  List<NearbyPoi> _allNearbyPois = [];
  bool _isTransportFilterActive = false;

  PhysicalAssistanceProvider({LocalStorageService? storageService})
      : _storageService = storageService ?? LocalStorageService() {
    loadCaregiverInfo();
  }

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  double? get accuracyMeters => _accuracyMeters;
  DateTime? get lastUpdatedTime => _lastUpdatedTime;
  String get currentAddress => _currentAddress;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isLocationServiceDisabled => _isLocationServiceDisabled;
  bool get isPermissionDenied => _isPermissionDenied;
  bool get isPermanentlyDenied => _isPermanentlyDenied;
  String? get locationError => _locationError;

  String get caregiverName => _caregiverName;
  String get caregiverPhone => _caregiverPhone;

  bool get isTransportFilterActive => _isTransportFilterActive;

  LocationDisplayState get locationState {
    if (_isLoadingLocation) return LocationDisplayState.loading;
    if (_isLocationServiceDisabled) return LocationDisplayState.serviceDisabled;
    if (_isPermanentlyDenied) return LocationDisplayState.permanentlyDenied;
    if (_isPermissionDenied) return LocationDisplayState.permissionDenied;
    if (_locationError != null) return LocationDisplayState.error;
    if (_latitude != null && _longitude != null) return LocationDisplayState.success;
    return LocationDisplayState.loading;
  }

  List<NearbyPoi> get nearbyPois {
    if (_isTransportFilterActive) {
      return _allNearbyPois.where((p) => p.category == 'transport').toList();
    }
    return List.unmodifiable(_allNearbyPois);
  }

  List<NearbyPoi> get transportPois =>
      _allNearbyPois.where((p) => p.category == 'transport').toList();

  Future<void> loadCaregiverInfo() async {
    final name = await _storageService.getString(_caregiverNameKey);
    final phone = await _storageService.getString(_caregiverPhoneKey);
    if (name != null) _caregiverName = name.trim();
    if (phone != null) _caregiverPhone = phone.trim();
    notifyListeners();
  }

  Future<void> updateCaregiverInfo(String name, String phone) async {
    _caregiverName = name.trim();
    _caregiverPhone = phone.trim();
    await _storageService.saveString(_caregiverNameKey, _caregiverName);
    await _storageService.saveString(_caregiverPhoneKey, _caregiverPhone);
    notifyListeners();
  }

  bool _isFetchInProgress = false;
  Future<void>? _activeFetchFuture;
  int _locationRequestId = 0;

  bool _isPlusCodeOrGarbage(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return true;
    // Pure numbers / numeric house numbers / punctuation (e.g. "517", "17", "425", "517425", "#12")
    if (RegExp(r'^[\d\s\,\-\/\#\.]+$').hasMatch(clean)) return true;
    // 6-digit postal PIN codes or 5-6 digit numbers (e.g. "517425", "517 425")
    if (RegExp(r'^\d{3}\s*\d{3}$').hasMatch(clean)) return true;
    // Plus codes or alphanumeric code fragments (e.g., "Q900+7", "Q900 7", "Q975 + H38")
    if (clean.contains('+')) return true;
    if (RegExp(r'^[A-Z0-9]{2,8}\s*[\+\s]\s*[A-Z0-9]{2,8}$', caseSensitive: false).hasMatch(clean)) return true;
    if (RegExp(r'^[A-Z][0-9]{3,5}\s+[0-9]', caseSensitive: false).hasMatch(clean)) return true;
    return false;
  }

  Future<void> fetchCurrentLocation({bool requestPermissionIfDenied = true}) async {
    debugPrint('[LOCATION_TRACE] command received');
    if (_isFetchInProgress && _activeFetchFuture != null) {
      debugPrint('[LOCATION_TRACE] Coalescing into active location fetch');
      return _activeFetchFuture!;
    }

    final int currentReqId = ++_locationRequestId;
    _isFetchInProgress = true;
    final completer = Completer<void>();
    _activeFetchFuture = completer.future;

    _isLoadingLocation = true;
    _isLocationServiceDisabled = false;
    _isPermissionDenied = false;
    _isPermanentlyDenied = false;
    _locationError = null;
    notifyListeners();

    try {
      debugPrint('[LOCATION_TRACE] checking service');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[LOCATION_TRACE] service_enabled=$serviceEnabled');
      if (!serviceEnabled) {
        _isLocationServiceDisabled = true;
        _locationError = 'Location services (GPS) are turned off on your device.';
        _currentAddress = 'Location service disabled. Turn on GPS in Android Settings.';
        _isLoadingLocation = false;
        debugPrint('[LOCATION_TRACE] error service_disabled');
        notifyListeners();
        return;
      }

      debugPrint('[LOCATION_TRACE] checking permission');
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[LOCATION_TRACE] permission=$permission');

      if (permission == LocationPermission.denied && requestPermissionIfDenied) {
        debugPrint('[LOCATION_TRACE] requesting permission');
        permission = await Geolocator.requestPermission();
        debugPrint('[LOCATION_TRACE] permission_result=$permission');
      }

      if (permission == LocationPermission.denied) {
        _isPermissionDenied = true;
        _locationError = 'Location permission is required.';
        _currentAddress = 'Location permission denied. Tap to grant access.';
        _isLoadingLocation = false;
        debugPrint('[LOCATION_TRACE] error permission_denied');
        notifyListeners();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _isPermanentlyDenied = true;
        _locationError = 'Location permission is blocked in Android Settings.';
        _currentAddress = 'Location permission permanently denied. Open App Settings to grant.';
        _isLoadingLocation = false;
        debugPrint('[LOCATION_TRACE] error permission_permanently_denied');
        notifyListeners();
        return;
      }

      debugPrint('[LOCATION_TRACE] requesting position');
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 6));
      } catch (e1) {
        debugPrint('[LOCATION_TRACE] High accuracy position timeout ($e1), falling back to medium accuracy...');
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
          ).timeout(const Duration(seconds: 5));
        } catch (e2) {
          debugPrint('[LOCATION_TRACE] Medium accuracy position timeout ($e2), attempting last known position...');
          pos = await Geolocator.getLastKnownPosition();
        }
      }

      if (currentReqId != _locationRequestId) {
        debugPrint('[LOCATION_TRACE] Discarding stale location request $currentReqId (current: $_locationRequestId)');
        return;
      }

      if (pos != null) {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _accuracyMeters = pos.accuracy;
        _lastUpdatedTime = DateTime.now();
        debugPrint('[LOCATION_TRACE] position received lat=${pos.latitude} lng=${pos.longitude} accuracy=${pos.accuracy}');

        debugPrint('[LOCATION_TRACE] geocoding');
        final humanAddr = await _reverseGeocode(pos.latitude, pos.longitude);
        if (currentReqId == _locationRequestId) {
          _currentAddress = humanAddr;
          _locationError = null;
          debugPrint('[LOCATION_TRACE] success address="$humanAddr"');
          _generateNearbyPois(_latitude!, _longitude!);
        }
      } else {
        throw Exception('Could not obtain current position or last known position.');
      }
    } catch (e) {
      debugPrint('[LOCATION_TRACE] error $e');
      debugPrint('[PhysicalAssistanceProvider] Location fetch error: $e');
      if (currentReqId == _locationRequestId) {
        _locationError = 'Unable to get your current location ($e).';
        if (_latitude != null && _longitude != null) {
          _currentAddress = 'Latitude ${_latitude!.toStringAsFixed(4)}, Longitude ${_longitude!.toStringAsFixed(4)}';
        } else {
          _currentAddress = 'Unable to retrieve location coordinates. Tap Try Again.';
        }
      }
    } finally {
      if (currentReqId == _locationRequestId) {
        _isLoadingLocation = false;
        notifyListeners();
      }
      _isFetchInProgress = false;
      _activeFetchFuture = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng).timeout(const Duration(seconds: 4));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];

        void addPart(String? raw) {
          if (raw == null) return;
          final clean = raw.trim();
          if (clean.isEmpty || _isPlusCodeOrGarbage(clean)) return;
          if (!parts.any((existing) => existing.toLowerCase() == clean.toLowerCase())) {
            parts.add(clean);
          }
        }

        // Hierarchy: Village (subLocality) -> Post/Sub-area -> City/Town (locality) -> District/Taluk (subAdministrativeArea) -> State (administrativeArea) -> Country (country)
        addPart(p.subLocality);
        addPart(p.subAdministrativeArea != p.locality ? p.subAdministrativeArea : null);
        addPart(p.locality);
        addPart(p.administrativeArea);
        addPart(p.country);

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {}
    return 'Latitude ${lat.toStringAsFixed(4)}, Longitude ${lng.toStringAsFixed(4)}';
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  void _generateNearbyPois(double lat, double lng) {
    // DO NOT fabricate fake POIs or mock coordinates.
    _allNearbyPois = [];
  }

  Future<void> openGoogleMapsNearbySearch({String query = 'places near me'}) async {
    final String searchUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    final uri = Uri.parse(searchUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[PhysicalAssistanceProvider] Error launching Google Maps search: $e');
    }
  }

  void toggleTransportFilter([bool? active]) {
    _isTransportFilterActive = active ?? !_isTransportFilterActive;
    notifyListeners();
  }

  Future<bool> callCaregiver() async {
    if (_caregiverPhone.trim().isEmpty) {
      return false;
    }
    final cleanPhone = _caregiverPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('[PhysicalAssistanceProvider] Error launching caregiver phone call: $e');
      return false;
    }
  }
}
