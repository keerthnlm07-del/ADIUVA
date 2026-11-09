import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service responsible for GPS coordinates and reverse geocoding for Emergency SOS
class LocationService {
  /// Check if location services (GPS hardware) are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[LOCATION_SERVICE] Error checking location service: $e');
      return false;
    }
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('[LOCATION_SERVICE] Error checking permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission from user
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('[LOCATION_SERVICE] Error requesting permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Acquire current device coordinates with timeout and fallback to last known position
  Future<Position?> getCurrentPosition({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LOCATION_SERVICE] Location services disabled on device.');
        return await _getLastKnownPosition();
      }

      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LOCATION_SERVICE] Location permission denied by user.');
          return await _getLastKnownPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LOCATION_SERVICE] Location permission denied forever.');
        return await _getLastKnownPosition();
      }

      // Attempt high accuracy position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      ).timeout(timeout);

      debugPrint(
        '[LOCATION_SERVICE] Current position acquired: ${position.latitude}, ${position.longitude} (acc: ${position.accuracy}m)',
      );
      return position;
    } catch (e) {
      debugPrint('[LOCATION_SERVICE] Exception acquiring current position: $e. Falling back to last known.');
      return await _getLastKnownPosition();
    }
  }

  Future<Position?> _getLastKnownPosition() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        debugPrint(
          '[LOCATION_SERVICE] Acquired last known position: ${lastKnown.latitude}, ${lastKnown.longitude}',
        );
      }
      return lastKnown;
    } catch (e) {
      debugPrint('[LOCATION_SERVICE] Error acquiring last known position: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to human-readable address
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    if (lat == 0.0 && lng == 0.0) return null;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 3));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if (p.street != null && p.street!.trim().isNotEmpty) p.street!.trim(),
          if (p.locality != null && p.locality!.trim().isNotEmpty) p.locality!.trim(),
          if (p.administrativeArea != null && p.administrativeArea!.trim().isNotEmpty)
            p.administrativeArea!.trim(),
          if (p.postalCode != null && p.postalCode!.trim().isNotEmpty) p.postalCode!.trim(),
        ];
        return parts.join(', ');
      }
    } catch (e) {
      debugPrint('[LOCATION_SERVICE] Reverse geocoding failed: $e');
    }
    return null;
  }
}
