import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adiuva/features/physical_assistance/presentation/provider/physical_assistance_provider.dart';
import 'package:adiuva/features/emergency_sos/presentation/provider/emergency_sos_provider.dart';
import 'package:adiuva/core/services/shake_detector_service.dart';
import 'package:adiuva/core/services/location_service.dart';
import 'package:adiuva/core/services/emergency_hardware_service.dart';
import 'package:adiuva/core/services/tts_service.dart';
import 'package:adiuva/core/services/local_storage_service.dart';
import 'package:adiuva/features/emergency_sos/data/datasources/emergency_remote_datasource.dart';
import 'package:adiuva/features/emergency_sos/domain/entities/emergency_event_entity.dart';
import 'package:adiuva/features/emergency_sos/domain/entities/emergency_contact_entity.dart';

// Test Fakes
class FakeEmergencyRemoteDataSource extends Fake implements EmergencyRemoteDataSource {
  EmergencyEventEntity? lastTriggeredEvent;
  String? lastUpdatedStatus;

  @override
  Future<void> triggerSosAlert(EmergencyEventEntity event) async {
    lastTriggeredEvent = event;
  }

  @override
  Future<void> updateSosStatus(String eventId, String status, [DateTime? resolvedAt]) async {
    lastUpdatedStatus = status;
  }

  @override
  Future<List<EmergencyContactEntity>> fetchEmergencyContacts(String userId) async {
    return [];
  }
}

class FakeTtsService extends Fake implements TtsService {
  final List<String> spokenMessages = [];
  bool isStopped = false;

  @override
  Future<void> speak(String text) async {
    spokenMessages.add(text);
  }

  @override
  Future<void> stop() async {
    isStopped = true;
  }
}

class FakeLocalStorageService extends Fake implements LocalStorageService {
  final Map<String, dynamic> storage = {};

  @override
  Future<String?> getString(String key) async {
    return storage[key] as String?;
  }

  @override
  Future<bool> saveString(String key, String value) async {
    storage[key] = value;
    return true;
  }
}

class FakeLocationService extends Fake implements LocationService {
  Position? mockPosition;
  bool shouldThrow = false;

  @override
  Future<Position?> getCurrentPosition({Duration timeout = const Duration(seconds: 5)}) async {
    if (shouldThrow) throw Exception('GPS hardware unavailable');
    return mockPosition;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;
}

class FakeEmergencyHardwareService extends Fake implements EmergencyHardwareService {
  SosHardwareResult smsResult = const SosHardwareResult(
    success: true,
    status: 'sent',
    message: 'SMS transmitted',
  );
  SosHardwareResult callResult = const SosHardwareResult(
    success: true,
    status: 'call_initiated',
    message: 'Call initiated',
  );
  String? lastSmsPhone;
  String? lastSmsMessage;
  String? lastCallPhone;

  @override
  Future<SosHardwareResult> sendDirectSms({
    required String phoneNumber,
    required String message,
  }) async {
    lastSmsPhone = phoneNumber;
    lastSmsMessage = message;
    return smsResult;
  }

  @override
  Future<SosHardwareResult> makeDirectCall({
    required String phoneNumber,
  }) async {
    lastCallPhone = phoneNumber;
    return callResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Physical Assistance & Location Tests', () {
    test('NearbyPoi initializes correctly with distance and category', () {
      final poi = NearbyPoi(
        name: 'City Bus Stop',
        distanceMeters: 45.0,
        category: 'transport',
        latitude: 12.9716,
        longitude: 77.5946,
      );

      expect(poi.name, equals('City Bus Stop'));
      expect(poi.distanceMeters, equals(45.0));
      expect(poi.category, equals('transport'));
    });
  });

  group('SOS State Machine Enum Tests', () {
    test('SosStateEnum has all required states including countdown', () {
      expect(SosStateEnum.values, contains(SosStateEnum.idle));
      expect(SosStateEnum.values, contains(SosStateEnum.countdown));
      expect(SosStateEnum.values, contains(SosStateEnum.confirmingDanger));
      expect(SosStateEnum.values, contains(SosStateEnum.waitingForCodeWord));
      expect(SosStateEnum.values, contains(SosStateEnum.triggering));
      expect(SosStateEnum.values, contains(SosStateEnum.success));
      expect(SosStateEnum.values, contains(SosStateEnum.active));
      expect(SosStateEnum.values, contains(SosStateEnum.cancelled));
      expect(SosStateEnum.values, contains(SosStateEnum.failure));
    });

    test('SosSmsStatus and SosCallStatus cover all physical-device states', () {
      expect(SosSmsStatus.values, contains(SosSmsStatus.sent));
      expect(SosSmsStatus.values, contains(SosSmsStatus.permissionDenied));
      expect(SosSmsStatus.values, contains(SosSmsStatus.failed));

      expect(SosCallStatus.values, contains(SosCallStatus.initiated));
      expect(SosCallStatus.values, contains(SosCallStatus.permissionDenied));
      expect(SosCallStatus.values, contains(SosCallStatus.failed));
    });
  });

  group('ShakeDetectorService Multi-Shake & Filter Tests', () {
    test('Rejects ordinary movement (walking / desk placement below 2.7g)', () {
      int shakeCount = 0;
      final detector = ShakeDetectorService(
        onShake: () => shakeCount++,
        shakeThresholdGravity: 2.7,
        shakeCountThreshold: 4,
      );

      // Normal walking: 12.0 m/s^2 (~1.22g)
      for (int i = 0; i < 10; i++) {
        detector.handleAccelerometerEvent(AccelerometerEvent(12.0, 0.0, 9.8, DateTime.now()));
      }

      expect(detector.currentShakeCount, equals(0));
      expect(shakeCount, equals(0));
    });

    test('Single sharp spike does not trigger SOS (requires 4 qualifying shakes)', () {
      int shakeCount = 0;
      final detector = ShakeDetectorService(
        onShake: () => shakeCount++,
        shakeThresholdGravity: 2.7,
        shakeCountThreshold: 4,
      );

      // Single vigorous drop or spike: 32 m/s^2 (~3.26g)
      detector.handleAccelerometerEvent(AccelerometerEvent(32.0, 0.0, 0.0, DateTime.now()));

      expect(detector.currentShakeCount, equals(1));
      expect(shakeCount, equals(0), reason: 'Single spike must not trigger SOS');
    });

    test('Rapid consecutive sensor samples during one stroke are debounced', () {
      int shakeCount = 0;
      final detector = ShakeDetectorService(
        onShake: () => shakeCount++,
        shakeThresholdGravity: 2.7,
        shakeCountThreshold: 4,
        minTimeBetweenShakesMs: 200,
      );

      // Multiple samples within 5ms of each other (same physical stroke)
      detector.handleAccelerometerEvent(AccelerometerEvent(30.0, 0.0, 0.0, DateTime.now()));
      detector.handleAccelerometerEvent(AccelerometerEvent(31.0, 0.0, 0.0, DateTime.now()));
      detector.handleAccelerometerEvent(AccelerometerEvent(29.0, 0.0, 0.0, DateTime.now()));

      expect(detector.currentShakeCount, equals(1), reason: 'Samples within debounce interval must count as 1 peak');
      expect(shakeCount, equals(0));
    });

    test('State guard (canTrigger) blocks shake detection when not in idle state', () {
      int shakeCount = 0;
      bool isIdle = false;

      final detector = ShakeDetectorService(
        onShake: () => shakeCount++,
        shakeThresholdGravity: 2.7,
        shakeCountThreshold: 4,
        canTrigger: () => isIdle,
      );

      detector.handleAccelerometerEvent(AccelerometerEvent(30.0, 0.0, 0.0, DateTime.now()));
      expect(detector.currentShakeCount, equals(0), reason: 'Must ignore shakes when canTrigger is false');
      expect(shakeCount, equals(0));

      // Now set to idle
      isIdle = true;
      detector.handleAccelerometerEvent(AccelerometerEvent(30.0, 0.0, 0.0, DateTime.now()));
      expect(detector.currentShakeCount, equals(1));
    });

    test('Cooldown period blocks shake events after activation', () {
      int shakeCount = 0;
      final detector = ShakeDetectorService(
        onShake: () => shakeCount++,
        shakeThresholdGravity: 2.7,
        shakeCountThreshold: 4,
        cooldownMs: 5000,
      );

      detector.startCooldown(5000);
      expect(detector.isInCooldown, isTrue);

      detector.handleAccelerometerEvent(AccelerometerEvent(35.0, 0.0, 0.0, DateTime.now()));
      expect(detector.currentShakeCount, equals(0), reason: 'Shake events during cooldown must be ignored');
      expect(shakeCount, equals(0));
    });
  });

  group('EmergencySosProvider 20-Second Countdown & Cancellation Tests', () {
    late FakeEmergencyRemoteDataSource fakeRemoteDataSource;
    late FakeTtsService fakeTtsService;
    late FakeLocalStorageService fakeStorageService;
    late FakeLocationService fakeLocationService;
    late FakeEmergencyHardwareService fakeHardwareService;
    late EmergencySosProvider provider;

    setUp(() async {
      fakeRemoteDataSource = FakeEmergencyRemoteDataSource();
      fakeTtsService = FakeTtsService();
      fakeStorageService = FakeLocalStorageService();
      fakeLocationService = FakeLocationService();
      fakeHardwareService = FakeEmergencyHardwareService();

      provider = EmergencySosProvider(
        remoteDataSource: fakeRemoteDataSource,
        ttsService: fakeTtsService,
        storageService: fakeStorageService,
        locationService: fakeLocationService,
        hardwareService: fakeHardwareService,
        enableShakeDetector: false, // controlled manually
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('startCountdown transitions to countdown state with 20 seconds and audible announcement', () {
      provider.startCountdown(source: 'test_shake');

      expect(provider.state, equals(SosStateEnum.countdown));
      expect(provider.countdownSeconds, equals(20));
      expect(fakeTtsService.spokenMessages, isNotEmpty);
      expect(fakeTtsService.spokenMessages.first, contains('20 seconds'));
    });

    test('cancelSosCountdown stops countdown, transitions to cancelled, and DOES NOT send SMS or Call', () async {
      provider.startCountdown(source: 'test_shake');
      expect(provider.state, equals(SosStateEnum.countdown));

      await provider.cancelSosCountdown();

      expect(provider.state, equals(SosStateEnum.cancelled));
      expect(fakeHardwareService.lastSmsPhone, isNull, reason: 'SMS must never be sent when cancelled');
      expect(fakeHardwareService.lastCallPhone, isNull, reason: 'Call must never be placed when cancelled');
      expect(fakeTtsService.isStopped, isTrue);
      expect(fakeTtsService.spokenMessages.last, contains('cancelled'));
    });

    test('Rapid duplicate countdown start is ignored when countdown is already active', () {
      provider.startCountdown(source: 'test_shake_1');
      expect(provider.state, equals(SosStateEnum.countdown));

      // Attempt second trigger
      provider.startCountdown(source: 'test_shake_2');
      expect(provider.state, equals(SosStateEnum.countdown));
      // Only 1 initial audible message
      expect(fakeTtsService.spokenMessages.length, equals(1));
    });
  });

  group('Automatic Emergency Workflow Execution Tests', () {
    late FakeEmergencyRemoteDataSource fakeRemoteDataSource;
    late FakeTtsService fakeTtsService;
    late FakeLocalStorageService fakeStorageService;
    late FakeLocationService fakeLocationService;
    late FakeEmergencyHardwareService fakeHardwareService;
    late EmergencySosProvider provider;

    setUp(() async {
      fakeRemoteDataSource = FakeEmergencyRemoteDataSource();
      fakeTtsService = FakeTtsService();
      fakeStorageService = FakeLocalStorageService();
      fakeLocationService = FakeLocationService();
      fakeHardwareService = FakeEmergencyHardwareService();

      fakeStorageService.storage['adiuva_sos_contact_name'] = 'Dr. Sharma';
      fakeStorageService.storage['adiuva_sos_contact_phone'] = '+919876543210';

      provider = EmergencySosProvider(
        remoteDataSource: fakeRemoteDataSource,
        ttsService: fakeTtsService,
        storageService: fakeStorageService,
        locationService: fakeLocationService,
        hardwareService: fakeHardwareService,
        enableShakeDetector: false,
      );
      await provider.loadEmergencySettings();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Automatic workflow formats SMS with GPS coordinates and sends direct SMS and Phone Call', () async {
      fakeLocationService.mockPosition = Position(
        latitude: 12.9716,
        longitude: 77.5946,
        timestamp: DateTime.now(),
        accuracy: 4.5,
        altitude: 920.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      await provider.executeAutomaticEmergencyWorkflow(userId: 'test_user_1', source: 'countdown_auto');

      expect(provider.state, equals(SosStateEnum.active));
      expect(provider.smsStatus, equals(SosSmsStatus.sent));
      expect(provider.callStatus, equals(SosCallStatus.initiated));

      // Verify SMS message content includes coordinates and maps link
      expect(fakeHardwareService.lastSmsPhone, equals('+919876543210'));
      expect(
        fakeHardwareService.lastSmsMessage,
        equals('EMERGENCY SOS! I may need immediate help. My current location: https://www.google.com/maps?q=12.971600,77.594600'),
      );

      // Verify Call phone number
      expect(fakeHardwareService.lastCallPhone, equals('+919876543210'));

      // Verify remote event logging
      expect(fakeRemoteDataSource.lastTriggeredEvent, isNotNull);
      expect(fakeRemoteDataSource.lastTriggeredEvent?.latitude, equals(12.9716));
      expect(fakeRemoteDataSource.lastTriggeredEvent?.longitude, equals(77.5946));
    });

    test('Automatic workflow falls back to location-unavailable message when GPS fails', () async {
      fakeLocationService.shouldThrow = true;

      await provider.executeAutomaticEmergencyWorkflow(userId: 'test_user_2', source: 'countdown_auto');

      expect(provider.state, equals(SosStateEnum.active));
      expect(fakeHardwareService.lastSmsPhone, equals('+919876543210'));
      expect(
        fakeHardwareService.lastSmsMessage,
        equals('EMERGENCY SOS! I may need immediate help. My current location could not be determined.'),
      );
    });

    test('Automatic workflow records permission denied honestly when hardware returns permission_denied', () async {
      fakeHardwareService.smsResult = const SosHardwareResult(
        success: false,
        status: 'permission_denied',
        message: 'SEND_SMS denied',
      );
      fakeHardwareService.callResult = const SosHardwareResult(
        success: false,
        status: 'permission_denied',
        message: 'CALL_PHONE denied',
      );

      await provider.executeAutomaticEmergencyWorkflow(userId: 'test_user_3', source: 'countdown_auto');

      expect(provider.smsStatus, equals(SosSmsStatus.permissionDenied));
      expect(provider.callStatus, equals(SosCallStatus.permissionDenied));
      expect(provider.smsStatusMessage, contains('permission denied'));
      expect(provider.callStatusMessage, contains('permission denied'));
    });

    test('Automatic workflow fails gracefully when no emergency contact is configured', () async {
      final emptyStorage = FakeLocalStorageService();
      final emptyHardware = FakeEmergencyHardwareService();
      final emptyProvider = EmergencySosProvider(
        remoteDataSource: fakeRemoteDataSource,
        ttsService: fakeTtsService,
        storageService: emptyStorage,
        locationService: fakeLocationService,
        hardwareService: emptyHardware,
        enableShakeDetector: false,
      );
      await emptyProvider.loadEmergencySettings();

      await emptyProvider.executeAutomaticEmergencyWorkflow(userId: 'test_user_4', source: 'countdown_auto');

      expect(emptyProvider.state, equals(SosStateEnum.failure));
      expect(emptyProvider.errorMessage, contains('No emergency contact'));
      expect(emptyHardware.lastSmsPhone, isNull);
      expect(emptyHardware.lastCallPhone, isNull);
      emptyProvider.dispose();
    });
  });
}
