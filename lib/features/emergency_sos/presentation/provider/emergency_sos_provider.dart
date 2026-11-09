import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/shake_detector_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/emergency_hardware_service.dart';
import '../../data/datasources/emergency_remote_datasource.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/entities/emergency_event_entity.dart';

/// Explicit State Machine Model for Emergency SOS Operations
enum SosStateEnum {
  idle,
  confirmingDanger,
  waitingForCodeWord,
  countdown,
  triggering,
  active,
  success,
  failure,
  cancelled,
}

/// Status of the automatic SMS dispatch
enum SosSmsStatus {
  none,
  sending,
  sent,
  permissionDenied,
  failed,
  openedComposer,
}

/// Status of the automatic emergency phone call
enum SosCallStatus {
  none,
  initiating,
  initiated,
  permissionDenied,
  failed,
  openedDialer,
}

/// Provider managing Emergency Contacts, Shake Detection & Shared SOS Action Pipeline
class EmergencySosProvider extends ChangeNotifier {
  final EmergencyRemoteDataSource _remoteDataSource;
  final TtsService _ttsService;
  final LocalStorageService _storageService;
  final LocationService _locationService;
  final EmergencyHardwareService _hardwareService;

  static const String _emergencyContactNameKey = 'adiuva_sos_contact_name';
  static const String _emergencyContactPhoneKey = 'adiuva_sos_contact_phone';
  static const String _emergencyCodeWordKey = 'adiuva_sos_code_word';

  List<EmergencyContactEntity> _contacts = [];
  SosStateEnum _state = SosStateEnum.idle;
  String? _activeEventId;
  String? _errorMessage;
  bool _isLoading = false;
  int _lastTriggerTimestamp = 0;

  // 20-second countdown state
  int _countdownSeconds = 20;
  Timer? _countdownTimer;

  // Hardware execution statuses
  SosSmsStatus _smsStatus = SosSmsStatus.none;
  SosCallStatus _callStatus = SosCallStatus.none;
  String? _smsStatusMessage;
  String? _callStatusMessage;

  String _contactName = '';
  String _contactPhone = '';
  String _emergencyCodeWord = '';

  ShakeDetectorService? _shakeDetector;
  final bool _isShakeDetectorEnabled;

  EmergencySosProvider({
    required EmergencyRemoteDataSource remoteDataSource,
    required TtsService ttsService,
    LocalStorageService? storageService,
    LocationService? locationService,
    EmergencyHardwareService? hardwareService,
    ShakeDetectorService? shakeDetector,
    bool enableShakeDetector = true,
  })  : _remoteDataSource = remoteDataSource,
        _ttsService = ttsService,
        _storageService = storageService ?? LocalStorageService(),
        _locationService = locationService ?? LocationService(),
        _hardwareService = hardwareService ?? EmergencyHardwareService(),
        _shakeDetector = shakeDetector,
        _isShakeDetectorEnabled = enableShakeDetector {
    loadEmergencySettings();
    if (_shakeDetector == null && _isShakeDetectorEnabled) {
      _initShakeDetector();
    }
  }

  List<EmergencyContactEntity> get contacts => List.unmodifiable(_contacts);
  SosStateEnum get state => _state;
  String? get activeEventId => _activeEventId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  int get countdownSeconds => _countdownSeconds;
  SosSmsStatus get smsStatus => _smsStatus;
  SosCallStatus get callStatus => _callStatus;
  String? get smsStatusMessage => _smsStatusMessage;
  String? get callStatusMessage => _callStatusMessage;

  String get contactName => _contactName;
  String get contactPhone => _contactPhone;
  String get emergencyCodeWord => _emergencyCodeWord;

  ShakeDetectorService? get shakeDetector => _shakeDetector;

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

  void _initShakeDetector() {
    _shakeDetector = ShakeDetectorService(
      onShake: _onShakeDetected,
      shakeThresholdGravity: 2.7,
      shakeCountThreshold: 4,
      shakeWindowMs: 3000,
      minTimeBetweenShakesMs: 200,
      cooldownMs: 10000,
      canTrigger: () => _state == SosStateEnum.idle,
    );
    _shakeDetector?.start();
  }

  /// Triggered when 4–5 strong qualifying phone shakes are detected within the time window
  void _onShakeDetected() {
    if (_state != SosStateEnum.idle) {
      debugPrint('[SOS_PROVIDER] Shake ignored: State is currently $_state');
      return;
    }

    debugPrint('[SOS_PROVIDER] Deliberate qualifying multi-shake detected -> Starting 20s countdown');
    startCountdown(source: 'shake');
  }

  Future<void> loadEmergencySettings() async {
    final name = await _storageService.getString(_emergencyContactNameKey);
    final phone = await _storageService.getString(_emergencyContactPhoneKey);
    final codeWord = await _storageService.getString(_emergencyCodeWordKey);

    if (name != null) _contactName = name.trim();
    if (phone != null) _contactPhone = phone.trim();
    if (codeWord != null) _emergencyCodeWord = codeWord.trim().toLowerCase();

    debugPrint('[SOS_TRACE] code_word_configured=${_emergencyCodeWord.isNotEmpty}');
    notifyListeners();
  }

  Future<void> updateEmergencySettings(String name, String phone, String codeWord) async {
    _contactName = name.trim();
    _contactPhone = phone.trim();
    _emergencyCodeWord = codeWord.trim().toLowerCase();

    await _storageService.saveString(_emergencyContactNameKey, _contactName);
    await _storageService.saveString(_emergencyContactPhoneKey, _contactPhone);
    await _storageService.saveString(_emergencyCodeWordKey, _emergencyCodeWord);

    debugPrint('[SOS_TRACE] code_word_saved=true');
    notifyListeners();
  }

  /// Step 1: Open Danger Confirmation State (for manual button clicks)
  void requestSosConfirmation() {
    if (_state != SosStateEnum.idle) return;
    _state = SosStateEnum.confirmingDanger;
    _errorMessage = null;
    notifyListeners();
    _ttsService.speak('Are you in danger? Say Yes to confirm, or No to cancel.');
  }

  /// Step 2: Transition to Code-Word Prompt State
  void promptForCodeWord() {
    _state = SosStateEnum.waitingForCodeWord;
    _errorMessage = null;
    debugPrint('[SOS_TRACE] waiting_for_code_word=true');
    notifyListeners();
    _ttsService.speak('Please say your emergency code word.');
  }

  /// Step 3: Verify Spoken Code Word and Trigger SOS on Match
  Future<void> verifyCodeWordAndSend(String rawSpokenCodeWord, String userId) async {
    debugPrint('[SOS_TRACE] code_word_received=true');
    if (_emergencyCodeWord.trim().isEmpty) {
      debugPrint('[SOS_PROVIDER] Emergency code word unconfigured.');
      _state = SosStateEnum.failure;
      _errorMessage = 'Please set an emergency code word in Settings.';
      await _ttsService.speak('Please set an emergency code word in Settings.');
      notifyListeners();
      return;
    }

    final normalizedInput = _normalizeText(rawSpokenCodeWord);
    final normalizedConfig = _normalizeText(_emergencyCodeWord);

    if (normalizedInput == normalizedConfig ||
        normalizedInput.contains(normalizedConfig) ||
        normalizedConfig.contains(normalizedInput)) {
      debugPrint('[SOS_PROVIDER] Emergency code word verified successfully.');
      await executeSharedSos(userId: userId, source: 'shake_codeword');
    } else {
      debugPrint('[SOS_PROVIDER] Emergency code word verification failed.');
      _state = SosStateEnum.cancelled;
      _errorMessage = 'Code word verification failed.';
      await _ttsService.speak('Emergency code word verification failed. SOS cancelled.');
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1500));
      _state = SosStateEnum.idle;
      notifyListeners();
    }
  }

  // =========================================================================
  // 20-SECOND COUNTDOWN & AUTOMATIC EMERGENCY WORKFLOW
  // =========================================================================

  /// Starts the visible 20-second countdown with audible warning.
  /// If cancelled, neither SMS nor Call will be initiated.
  /// If not cancelled, automatically proceeds to location fetch, SMS, and Call.
  void startCountdown({String source = 'shake', String userId = ''}) {
    if (_state == SosStateEnum.countdown ||
        _state == SosStateEnum.triggering ||
        _state == SosStateEnum.active) {
      debugPrint('[SOS_PROVIDER] Countdown start ignored: State is $_state');
      return;
    }

    _countdownSeconds = 20;
    _state = SosStateEnum.countdown;
    _errorMessage = null;
    _smsStatus = SosSmsStatus.none;
    _callStatus = SosCallStatus.none;
    _smsStatusMessage = null;
    _callStatusMessage = null;
    notifyListeners();

    // Auto-navigate to Emergency SOS page if not currently visible
    try {
      final nav = AppRoutes.navigatorKey.currentState;
      if (nav != null) {
        nav.pushNamed(AppRoutes.emergencySos);
      }
    } catch (e) {
      debugPrint('[SOS_PROVIDER] Navigation error: $e');
    }

    // Audible Warning
    _ttsService.speak(
      'Emergency SOS triggered. Alert sending in 20 seconds. Press cancel to abort.',
    );

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      notifyListeners();

      // Audible checkpoints during countdown
      if (_countdownSeconds == 15) {
        _ttsService.speak('15 seconds.');
      } else if (_countdownSeconds == 10) {
        _ttsService.speak('10 seconds remaining.');
      } else if (_countdownSeconds == 5) {
        _ttsService.speak('5');
      } else if (_countdownSeconds == 4) {
        _ttsService.speak('4');
      } else if (_countdownSeconds == 3) {
        _ttsService.speak('3');
      } else if (_countdownSeconds == 2) {
        _ttsService.speak('2');
      } else if (_countdownSeconds == 1) {
        _ttsService.speak('1');
      } else if (_countdownSeconds <= 0) {
        timer.cancel();
        _countdownTimer = null;
        debugPrint('[SOS_PROVIDER] 20-second countdown expired -> Executing Automatic Emergency Workflow');
        executeAutomaticEmergencyWorkflow(userId: userId, source: source);
      }
    });
  }

  /// Cancels the 20-second countdown.
  /// Strictly prevents SMS and Phone Call from occurring.
  Future<void> cancelSosCountdown() async {
    debugPrint('[SOS_PROVIDER] User cancelled SOS countdown.');
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownSeconds = 20;

    _ttsService.stop();
    _shakeDetector?.startCooldown(15000); // 15-second cooldown after cancellation

    _state = SosStateEnum.cancelled;
    _errorMessage = null;
    await _ttsService.speak('Emergency alert cancelled.');
    notifyListeners();

    unawaited(Future.delayed(const Duration(milliseconds: 2000), () {
      if (_state == SosStateEnum.cancelled) {
        _state = SosStateEnum.idle;
        notifyListeners();
      }
    }));
  }

  /// Resolves the target emergency phone number
  String getEffectiveEmergencyPhone() {
    if (_contactPhone.trim().isNotEmpty) {
      return _contactPhone.trim();
    }
    if (_contacts.isNotEmpty && _contacts.first.phone.trim().isNotEmpty) {
      return _contacts.first.phone.trim();
    }
    return '';
  }

  /// Executes the automatic emergency workflow after the 20-second countdown expires.
  /// 1. Fetches phone's current GPS coordinates with location service.
  /// 2. Composes message:
  ///    "EMERGENCY SOS! I may need immediate help. My current location: https://www.google.com/maps?q=LATITUDE,LONGITUDE"
  /// 3. Sends SMS automatically via native Android SmsManager (or honest fallback if blocked).
  /// 4. Initiates direct phone call via native Android Intent.ACTION_CALL (or dialer fallback).
  /// 5. Records and updates actual status.
  Future<void> executeAutomaticEmergencyWorkflow({
    String userId = '',
    String source = 'countdown',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTriggerTimestamp < 8000) {
      debugPrint('[SOS_PROVIDER] Rapid duplicate trigger ignored (cooldown active).');
      return;
    }
    _lastTriggerTimestamp = now;

    _state = SosStateEnum.triggering;
    _errorMessage = null;
    _smsStatus = SosSmsStatus.sending;
    _callStatus = SosCallStatus.initiating;
    notifyListeners();

    await _ttsService.speak('Alert activating. Sending emergency SMS and initiating phone call.');

    // 1. Acquire Location
    double lat = 0.0;
    double lng = 0.0;
    bool hasGps = false;

    try {
      final position = await _locationService.getCurrentPosition(
        timeout: const Duration(seconds: 5),
      );
      if (position != null && (position.latitude != 0.0 || position.longitude != 0.0)) {
        lat = position.latitude;
        lng = position.longitude;
        hasGps = true;
      }
    } catch (e) {
      debugPrint('[SOS_PROVIDER] GPS fetch error during automatic SOS: $e');
    }

    // 2. Compose Location Message
    final String fullMessageText;
    if (hasGps) {
      final mapsUrl = 'https://www.google.com/maps?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
      fullMessageText = 'EMERGENCY SOS! I may need immediate help. My current location: $mapsUrl';
    } else {
      fullMessageText = 'EMERGENCY SOS! I may need immediate help. My current location could not be determined.';
    }

    final targetPhone = getEffectiveEmergencyPhone();
    if (targetPhone.isEmpty) {
      _state = SosStateEnum.failure;
      _smsStatus = SosSmsStatus.failed;
      _callStatus = SosCallStatus.failed;
      _errorMessage = 'No emergency contact set. Please configure an emergency contact in Settings.';
      await _ttsService.speak('No emergency contact configured. Call emergency services directly.');
      notifyListeners();
      return;
    }

    final eventId = 'sos_$now';
    _activeEventId = eventId;

    // 3. Log remote event if user ID is present
    try {
      final event = EmergencyEventEntity(
        eventId: eventId,
        userId: userId.isEmpty ? 'guest_user' : userId,
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        status: 'automatic_triggered',
        contactsAttempted: [targetPhone],
      );
      if (userId.isNotEmpty) {
        await _remoteDataSource.triggerSosAlert(event);
      }
    } catch (e) {
      debugPrint('[SOS_PROVIDER] Cloud event log failed: $e');
    }

    // 4. Send Automatic Direct SMS via Native Android Service
    final smsResult = await _hardwareService.sendDirectSms(
      phoneNumber: targetPhone,
      message: fullMessageText,
    );

    if (smsResult.success) {
      _smsStatus = SosSmsStatus.sent;
      _smsStatusMessage = 'Direct SMS sent: ${smsResult.message}';
    } else if (smsResult.status == 'permission_denied') {
      _smsStatus = SosSmsStatus.permissionDenied;
      _smsStatusMessage = 'SMS permission denied. Opened composer fallback.';
    } else {
      _smsStatus = SosSmsStatus.failed;
      _smsStatusMessage = 'SMS failed: ${smsResult.message}';
    }
    notifyListeners();

    // 5. Initiate Automatic Direct Phone Call without requiring another tap
    final callResult = await _hardwareService.makeDirectCall(
      phoneNumber: targetPhone,
    );

    if (callResult.success) {
      _callStatus = SosCallStatus.initiated;
      _callStatusMessage = 'Direct emergency call initiated to $targetPhone';
    } else if (callResult.status == 'permission_denied') {
      _callStatus = SosCallStatus.permissionDenied;
      _callStatusMessage = 'CALL_PHONE permission denied. Opened dialer fallback.';
    } else {
      _callStatus = SosCallStatus.failed;
      _callStatusMessage = 'Call failed: ${callResult.message}';
    }

    _state = SosStateEnum.active;
    _shakeDetector?.startCooldown(30000); // 30s cooldown while emergency active
    await _ttsService.speak('Emergency alert transmitted. Direct call initiated.');
    notifyListeners();
  }

  /// Legacy helper method for backward compatibility
  Future<void> confirmAndSendSos(String userId, {String source = 'manual'}) async {
    await executeSharedSos(userId: userId, source: source);
  }

  /// Shared Emergency Execution Pipeline — for Manual Triggering
  Future<void> executeSharedSos({required String userId, String source = 'manual'}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTriggerTimestamp < 8000) {
      debugPrint('[SOS_PROVIDER] Rapid duplicate trigger ignored (cooldown active).');
      return;
    }
    _lastTriggerTimestamp = now;

    _state = SosStateEnum.triggering;
    _errorMessage = null;
    notifyListeners();

    final eventId = 'sos_$now';
    _activeEventId = eventId;

    double lat = 0.0;
    double lng = 0.0;
    bool hasGps = false;

    try {
      final position = await _locationService.getCurrentPosition(
        timeout: const Duration(seconds: 5),
      );
      if (position != null && (position.latitude != 0.0 || position.longitude != 0.0)) {
        lat = position.latitude;
        lng = position.longitude;
        hasGps = true;
      }
    } catch (e) {
      debugPrint('[SOS_PROVIDER] GPS fetch fallback for SOS: $e');
    }

    final targetPhone = getEffectiveEmergencyPhone();

    final String fullMessageText;
    if (hasGps) {
      final mapsUrl = 'https://www.google.com/maps?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
      fullMessageText = 'EMERGENCY SOS! I may need immediate help. My current location: $mapsUrl';
    } else {
      fullMessageText = 'EMERGENCY SOS! I may need immediate help. My current location could not be determined.';
    }

    final event = EmergencyEventEntity(
      eventId: eventId,
      userId: userId.isEmpty ? 'guest_user' : userId,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      status: 'triggered',
      contactsAttempted: targetPhone.isNotEmpty ? [targetPhone] : [],
    );

    try {
      if (userId.isNotEmpty) {
        try {
          await _remoteDataSource.triggerSosAlert(event);
        } catch (_) {}
      }

      _state = SosStateEnum.success;
      await _ttsService.speak('Emergency SOS alert activated. Emergency contact notified with location.');

      if (targetPhone.isNotEmpty) {
        await _hardwareService.sendDirectSms(
          phoneNumber: targetPhone,
          message: fullMessageText,
        );
      }
    } catch (e) {
      _state = SosStateEnum.failure;
      _errorMessage = 'Unable to complete full alert. Please call emergency services directly.';
      await _ttsService.speak('Emergency alert failed. Call emergency services.');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> callEmergencyContact() async {
    final phone = getEffectiveEmergencyPhone();
    if (phone.isEmpty) return false;
    final res = await _hardwareService.makeDirectCall(phoneNumber: phone);
    return res.success;
  }

  Future<bool> sendSmsSos({String? customMessage}) async {
    final phone = getEffectiveEmergencyPhone();
    if (phone.isEmpty) return false;
    final msg = customMessage ?? 'EMERGENCY SOS ALERT! I need immediate help.';
    final res = await _hardwareService.sendDirectSms(
      phoneNumber: phone,
      message: msg,
    );
    return res.success;
  }

  Future<bool> sendWhatsAppSos({String? customMessage}) async {
    final phone = getEffectiveEmergencyPhone();
    if (phone.isEmpty) return false;
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final msg = customMessage ?? 'EMERGENCY SOS ALERT! I need immediate help.';
    final encodedMsg = Uri.encodeComponent(msg);

    final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMsg');
    final webWhatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        debugPrint('[SOS_PROVIDER] WhatsApp opened with SOS message');
        return true;
      } else if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
        debugPrint('[SOS_PROVIDER] WhatsApp opened with SOS message');
        return true;
      }
    } catch (e) {
      debugPrint('[SOS_PROVIDER] Error launching WhatsApp intent: $e');
    }
    return false;
  }

  /// Cancel SOS Flow and Reset State Machine
  Future<void> cancelSos() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownSeconds = 20;

    if (_activeEventId != null && (_state == SosStateEnum.success || _state == SosStateEnum.active)) {
      try {
        await _remoteDataSource.updateSosStatus(_activeEventId!, 'cancelled');
      } catch (_) {}
    }

    _shakeDetector?.startCooldown(15000);
    _state = SosStateEnum.cancelled;
    _errorMessage = null;
    await _ttsService.speak('Emergency SOS alert cancelled.');
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));
    _state = SosStateEnum.idle;
    notifyListeners();
  }

  Future<void> resolveSos() async {
    await cancelSos();
  }

  void resetState() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownSeconds = 20;
    _state = SosStateEnum.idle;
    _errorMessage = null;
    notifyListeners();
  }

  String _normalizeText(String text) {
    return text.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeDetector?.dispose();
    super.dispose();
  }
}
