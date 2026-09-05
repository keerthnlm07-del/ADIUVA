import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/tts_service.dart';
import '../../data/datasources/emergency_remote_datasource.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/entities/emergency_event_entity.dart';

/// Explicit State Model for Emergency SOS Operations
enum SosStateEnum {
  idle,
  confirmation,
  sending,
  success,
  failure,
  cancelled,
}

/// Provider managing Emergency Contacts and SOS Alert State Machine
class EmergencySosProvider extends ChangeNotifier {
  final EmergencyRemoteDataSource _remoteDataSource;
  final TtsService _ttsService;

  List<EmergencyContactEntity> _contacts = [];
  SosStateEnum _state = SosStateEnum.idle;
  String? _activeEventId;
  String? _errorMessage;
  bool _isLoading = false;

  EmergencySosProvider({
    required EmergencyRemoteDataSource remoteDataSource,
    required TtsService ttsService,
  })  : _remoteDataSource = remoteDataSource,
        _ttsService = ttsService;

  List<EmergencyContactEntity> get contacts => List.unmodifiable(_contacts);
  SosStateEnum get state => _state;
  String? get activeEventId => _activeEventId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  /// Fetch user emergency contacts from Cloud Firestore
  Future<void> fetchContacts(String userId) async {
    if (userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      _contacts = await _remoteDataSource.fetchEmergencyContacts(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load emergency contacts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new emergency contact to Cloud Firestore
  Future<void> addContact(EmergencyContactEntity contact) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _remoteDataSource.addEmergencyContact(contact);
      _contacts.add(contact);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to add emergency contact: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete emergency contact from Cloud Firestore
  Future<void> deleteContact(String contactId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _remoteDataSource.deleteEmergencyContact(contactId);
      _contacts.removeWhere((c) => c.contactId == contactId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to delete contact: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Step 1: Open Confirmation State (Prevent accidental trigger)
  void requestSosConfirmation() {
    _state = SosStateEnum.confirmation;
    _errorMessage = null;
    notifyListeners();
  }

  /// Step 2: User Confirms SOS Alert Transmission
  Future<void> confirmAndSendSos(String userId) async {
    if (userId.isEmpty) return;

    _state = SosStateEnum.sending;
    _errorMessage = null;
    notifyListeners();

    final eventId = 'sos_${DateTime.now().millisecondsSinceEpoch}';
    _activeEventId = eventId;

    double lat = 0.0;
    double lng = 0.0;

    // Fetch GPS coordinates
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 5));
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {}

    final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
    final attemptedPhones = _contacts.map((c) => c.phone).toList();

    final event = EmergencyEventEntity(
      eventId: eventId,
      userId: userId,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      status: 'triggered',
      contactsAttempted: attemptedPhones,
    );

    try {
      await _remoteDataSource.triggerSosAlert(event);
      _state = SosStateEnum.success;
      await _ttsService.speak('Emergency SOS alert transmitted. Location shared with contacts.');

      // Prefill SMS or WhatsApp intent for emergency contacts
      if (_contacts.isNotEmpty) {
        final firstPhone = _contacts.first.phone;
        final message = Uri.encodeComponent('EMERGENCY ALERT from ADiUVA user! I need help. My current location: $mapsUrl');
        final smsUri = Uri.parse('sms:$firstPhone?body=$message');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      _state = SosStateEnum.failure;
      _errorMessage = 'Unable to send emergency alert. Please try again.';
      await _ttsService.speak('Emergency alert failed to transmit.');
    } finally {
      notifyListeners();
    }
  }

  /// User Cancels Confirmation or Active SOS Event
  Future<void> cancelSos() async {
    if (_activeEventId != null && _state == SosStateEnum.success) {
      try {
        await _remoteDataSource.updateSosStatus(_activeEventId!, 'cancelled');
      } catch (_) {}
    }

    _state = SosStateEnum.cancelled;
    _errorMessage = null;
    await _ttsService.speak('Emergency SOS alert cancelled.');
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));
    _state = SosStateEnum.idle;
    notifyListeners();
  }

  /// Resolve / Cancel SOS event alias
  Future<void> resolveSos() async {
    await cancelSos();
  }

  /// Reset state machine to idle
  void resetState() {
    _state = SosStateEnum.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
