import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/core/services/camera_service.dart';
import 'package:adiuva/core/services/tts_service.dart';
import 'package:adiuva/features/visual_assistance/data/datasources/adiuva_object_classifier_service.dart';
import 'package:adiuva/features/visual_assistance/data/datasources/document_reader_service.dart';
import 'package:adiuva/features/visual_assistance/data/datasources/ml_kit_barcode_service.dart';
import 'package:adiuva/features/visual_assistance/data/datasources/ml_kit_ocr_service.dart';
import 'package:adiuva/features/visual_assistance/data/datasources/scene_description_service.dart';
import 'package:adiuva/features/visual_assistance/data/datasources/yolo_tflite_service.dart';
import 'package:adiuva/features/visual_assistance/presentation/provider/visual_assistance_provider.dart';

// Test Fakes
class FakeCameraService extends Fake implements CameraService {
  @override
  bool get isInitialized => false;
  @override
  bool get isStreaming => false;
  @override
  bool get isFlashOn => false;
  @override
  Future<void> stopImageStream() async {}
}

class FakeOcrService extends Fake implements MlKitOcrService {}
class FakeDetectionService extends Fake implements YoloTfliteService {
  List<DetectedObjectBox> mockBoxes = [];

  @override
  Future<List<DetectedObjectBox>> detectObjects(String imagePath) async {
    return mockBoxes;
  }
}
class FakeBarcodeService extends Fake implements MlKitBarcodeService {}
class FakeSceneService extends Fake implements SceneDescriptionService {}

class FakeTtsService extends ChangeNotifier implements TtsService {
  bool _isSpeaking = false;
  final List<String> spokenTexts = [];
  final List<VoidCallback> _completionListeners = [];

  @override
  bool get isSpeaking => _isSpeaking;

  set isSpeaking(bool value) {
    _isSpeaking = value;
    notifyListeners();
  }

  @override
  Future<void> speak(String text) async {
    spokenTexts.add(text);
    _isSpeaking = true;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void addCompletionListener(VoidCallback onComplete) {
    _completionListeners.add(onComplete);
  }

  @override
  void removeCompletionListener(VoidCallback onComplete) {
    _completionListeners.remove(onComplete);
  }

  @override
  void setCompletionListener(VoidCallback onComplete) {
    _completionListeners.add(onComplete);
  }

  @override
  Future<void> setLanguage(String languageCode) async {}
  @override
  Future<void> setSpeechRate(double rate) async {}
  @override
  Future<void> setPitch(double pitch) async {}
  @override
  Future<void> setVolume(double volume) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adiuva Object Classifier Service Natural Language Tests', () {
    late AdiuvaObjectClassifierService classifierService;

    setUp(() {
      classifierService = AdiuvaObjectClassifierService();
    });

    test('Initializes default 19 object categories exactly matching dataset', () {
      final labels = classifierService.labels;
      expect(labels.length, equals(19));
      expect(labels, containsAll([
        'book',
        'bottle',
        'chair',
        'chalk',
        'charger',
        'cup',
        'earphone_case',
        'keyboard',
        'keys',
        'laptop',
        'mobile_phone',
        'mouse',
        'paper',
        'pen',
        'pencil',
        'person',
        'table',
        'wallet',
        'watch',
      ]));
    });

    test('Formats display names correctly for multi-word and single-word labels', () {
      expect(AdiuvaObjectClassifierService.formatDisplayName('book'), equals('Book'));
      expect(AdiuvaObjectClassifierService.formatDisplayName('earphone_case'), equals('Earphone Case'));
      expect(AdiuvaObjectClassifierService.formatDisplayName('mobile_phone'), equals('Mobile Phone'));
      expect(AdiuvaObjectClassifierService.formatDisplayName('keys'), equals('Keys'));
      expect(AdiuvaObjectClassifierService.formatDisplayName('watch'), equals('Watch'));
    });

    test('ClassConfidence toString() contains NO percentages or numbers', () {
      const conf = ClassConfidence(label: 'bottle', displayName: 'Bottle', confidence: 0.942);
      expect(conf.toString(), equals('Bottle'));
      expect(conf.toString(), isNot(contains('%')));
      expect(conf.toString(), isNot(contains('94')));
      // Internal confidence score is preserved for model thresholding/ranking
      expect(conf.confidence, equals(0.942));
      expect(conf.confidencePercent, equals(94));
    });

    test('Formats natural sentences for key required categories without percentages', () {
      // Person
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('person', 'Person'),
        equals('A person is standing in front of you.'),
      );
      // Chair
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('chair', 'Chair'),
        equals('There is a chair ahead of you.'),
      );
      // Bottle
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('bottle', 'Bottle'),
        equals('A bottle is visible in front of you.'),
      );
      // Keys
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('keys', 'Keys'),
        equals('Keys are visible in front of you.'),
      );
      // Laptop
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('laptop', 'Laptop'),
        equals('A laptop is in front of you.'),
      );
      // Mobile Phone
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('mobile_phone', 'Mobile Phone'),
        equals('A mobile phone is in front of you.'),
      );
    });

    test('Verified spatial direction: left, right, and ahead formatting', () {
      // Person with verified directions
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('person', 'Person', direction: SpatialDirection.left),
        equals('A person is on your left.'),
      );
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('person', 'Person', direction: SpatialDirection.right),
        equals('A person is on your right.'),
      );
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('person', 'Person', direction: SpatialDirection.ahead),
        equals('A person is standing in front of you.'),
      );

      // Chair with verified directions
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('chair', 'Chair', direction: SpatialDirection.left),
        equals('There is a chair to your left.'),
      );
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('chair', 'Chair', direction: SpatialDirection.right),
        equals('There is a chair to your right.'),
      );
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('chair', 'Chair', direction: SpatialDirection.ahead),
        equals('There is a chair ahead of you.'),
      );

      // Bottle with verified directions
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('bottle', 'Bottle', direction: SpatialDirection.left),
        equals('A bottle is on your left.'),
      );
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('bottle', 'Bottle', direction: SpatialDirection.right),
        equals('A bottle is on your right.'),
      );
      expect(
        AdiuvaObjectClassifierService.formatNaturalPhrase('bottle', 'Bottle', direction: SpatialDirection.ahead),
        equals('A bottle is visible in front of you.'),
      );
    });

    test('YOLO DetectedObjectBox correctly derives spatial direction from bounding box', () {
      // Left side: cx < 0.35
      final leftBox = DetectedObjectBox(
        label: 'chair',
        confidence: 0.9,
        left: 0.05,
        top: 0.2,
        right: 0.30,
        bottom: 0.8,
      );
      expect(leftBox.spatialDirection, equals(SpatialDirection.left));

      // Right side: cx > 0.65
      final rightBox = DetectedObjectBox(
        label: 'bottle',
        confidence: 0.88,
        left: 0.70,
        top: 0.3,
        right: 0.95,
        bottom: 0.7,
      );
      expect(rightBox.spatialDirection, equals(SpatialDirection.right));

      // Center / ahead: 0.35 <= cx <= 0.65
      final centerBox = DetectedObjectBox(
        label: 'person',
        confidence: 0.95,
        left: 0.35,
        top: 0.1,
        right: 0.65,
        bottom: 0.9,
      );
      expect(centerBox.spatialDirection, equals(SpatialDirection.ahead));
    });

    test('Spoken output via ObjectClassificationResult never contains percentages', () {
      const topResult = ObjectClassificationResult(
        label: 'mobile_phone',
        displayName: 'Mobile Phone',
        confidence: 0.942,
        topAlternatives: [
          ClassConfidence(label: 'mobile_phone', displayName: 'Mobile Phone', confidence: 0.942),
          ClassConfidence(label: 'laptop', displayName: 'Laptop', confidence: 0.038),
          ClassConfidence(label: 'table', displayName: 'Table', confidence: 0.012),
        ],
        inferenceTimeMs: 18,
      );

      final spoken = topResult.toNaturalSpeech();
      expect(spoken, equals('A mobile phone is in front of you.'));
      expect(spoken, isNot(contains('%')));
      expect(spoken, isNot(contains('percent')));
      expect(spoken, isNot(contains('confidence')));
      expect(spoken, isNot(contains('94')));
      expect(topResult.toAccessibleSpokenText(), equals('A mobile phone is in front of you.'));
    });

    test('Gracefully handles missing or non-existent image paths without throwing exceptions', () async {
      final result = await classifierService.classifyImage('/non/existent/path/image.jpg');
      expect(result, isNull);
    });
  });

  group('VisualAssistanceProvider Smart Announcement & Zero Percentage Tests', () {
    late VisualAssistanceProvider provider;
    late FakeTtsService fakeTtsService;
    late FakeCameraService fakeCameraService;
    late FakeDetectionService fakeDetectionService;

    setUp(() {
      fakeCameraService = FakeCameraService();
      fakeTtsService = FakeTtsService();
      fakeDetectionService = FakeDetectionService();
      provider = VisualAssistanceProvider(
        cameraService: fakeCameraService,
        ocrService: FakeOcrService(),
        detectionService: fakeDetectionService,
        barcodeService: FakeBarcodeService(),
        sceneService: FakeSceneService(),
        ttsService: fakeTtsService,
        documentReaderService: DocumentReaderService(ocrService: FakeOcrService()),
      );
    });

    test('Confidence Filtering: weak predictions (< 70%) produce zero announcements', () {
      final baseTime = DateTime(2026, 10, 26, 12, 0, 0);

      // Prediction at 8% (weak prediction)
      const weakPrediction = ObjectClassificationResult(
        label: 'bottle',
        displayName: 'Bottle',
        confidence: 0.08,
        topAlternatives: [],
        inferenceTimeMs: 15,
      );

      provider.handleContinuousMonitoringResult(weakPrediction, nowOverride: baseTime);

      expect(fakeTtsService.spokenTexts, isEmpty);
      expect(provider.currentIdentifiedClass, isNull);

      // Prediction at 69% (just below 70% threshold)
      const borderlinePrediction = ObjectClassificationResult(
        label: 'mobile_phone',
        displayName: 'Mobile Phone',
        confidence: 0.69,
        topAlternatives: [],
        inferenceTimeMs: 15,
      );

      provider.handleContinuousMonitoringResult(borderlinePrediction, nowOverride: baseTime);

      expect(fakeTtsService.spokenTexts, isEmpty);
      expect(provider.currentIdentifiedClass, isNull);
    });

    test('Initial Announcement: reliable prediction (>= 70%) triggers speech once in natural language with zero percentages', () {
      final baseTime = DateTime(2026, 10, 26, 12, 0, 0);

      const reliablePrediction = ObjectClassificationResult(
        label: 'mobile_phone',
        displayName: 'Mobile Phone',
        confidence: 0.88,
        topAlternatives: [
          ClassConfidence(label: 'mobile_phone', displayName: 'Mobile Phone', confidence: 0.88),
          ClassConfidence(label: 'laptop', displayName: 'Laptop', confidence: 0.08),
        ],
        inferenceTimeMs: 16,
      );

      provider.handleContinuousMonitoringResult(reliablePrediction, nowOverride: baseTime);

      expect(fakeTtsService.spokenTexts.length, equals(1));
      expect(fakeTtsService.spokenTexts.first, equals('A mobile phone is in front of you.'));
      expect(fakeTtsService.spokenTexts.first, isNot(contains('%')));
      expect(fakeTtsService.spokenTexts.first, isNot(contains('88')));
      expect(provider.currentIdentifiedClass, equals('mobile_phone'));
      expect(provider.lastAnnouncementTime, equals(baseTime));

      // Check on-screen labels: zero percentages!
      expect(provider.lastResult, isNotNull);
      for (final label in provider.lastResult!.labels) {
        expect(label, isNot(contains('%')));
        expect(label, isNot(contains('(')));
      }
      expect(provider.lastResult!.labels, contains('Mobile Phone'));
      expect(provider.lastResult!.labels, contains('Laptop'));
    });

    test('Duplicate Suppression: continuous frames of same object do NOT announce on every frame', () {
      final baseTime = DateTime(2026, 10, 26, 12, 0, 0);

      const phoneResult = ObjectClassificationResult(
        label: 'mobile_phone',
        displayName: 'Mobile Phone',
        confidence: 0.88,
        topAlternatives: [],
        inferenceTimeMs: 15,
      );

      // Frame 1 at t = 0.0s (First appearance)
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime);
      fakeTtsService.isSpeaking = false;
      expect(fakeTtsService.spokenTexts.length, equals(1));

      // Subsequent frames at 500ms, 1s, 2s, 5s, 9.9s
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime.add(const Duration(milliseconds: 500)));
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime.add(const Duration(seconds: 1)));
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime.add(const Duration(seconds: 2)));
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime.add(const Duration(seconds: 5)));
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime.add(const Duration(milliseconds: 9900)));

      // Must remain exactly 1 announcement
      expect(fakeTtsService.spokenTexts.length, equals(1));
    });

    test('10-Second Interval: continuously visible object re-announces every 10 seconds in natural language', () {
      final baseTime = DateTime(2026, 10, 26, 12, 0, 0);

      const phoneResult = ObjectClassificationResult(
        label: 'mobile_phone',
        displayName: 'Mobile Phone',
        confidence: 0.88,
        topAlternatives: [],
        inferenceTimeMs: 15,
      );

      // t = 0s -> 1st announcement
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime);
      fakeTtsService.isSpeaking = false;
      expect(fakeTtsService.spokenTexts.length, equals(1));

      // t = 5s -> suppressed
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime.add(const Duration(seconds: 5)));
      expect(fakeTtsService.spokenTexts.length, equals(1));

      // t = 10.1s (>= 10s elapsed) -> 2nd announcement
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime.add(const Duration(milliseconds: 10100)));
      fakeTtsService.isSpeaking = false;
      expect(fakeTtsService.spokenTexts.length, equals(2));
      expect(fakeTtsService.spokenTexts[1], equals('A mobile phone is in front of you.'));

      // t = 15s -> suppressed
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime.add(const Duration(seconds: 15)));
      expect(fakeTtsService.spokenTexts.length, equals(2));

      // t = 20.2s (>= 10s elapsed since last announcement) -> 3rd announcement
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime.add(const Duration(milliseconds: 20200)));
      fakeTtsService.isSpeaking = false;
      expect(fakeTtsService.spokenTexts.length, equals(3));
    });

    test('Changed Object: new reliable object announces immediately in natural language', () {
      final baseTime = DateTime(2026, 10, 26, 12, 0, 0);

      const phoneResult = ObjectClassificationResult(
        label: 'mobile_phone',
        displayName: 'Mobile Phone',
        confidence: 0.85,
        topAlternatives: [],
        inferenceTimeMs: 15,
      );

      const keysResult = ObjectClassificationResult(
        label: 'keys',
        displayName: 'Keys',
        confidence: 0.90,
        topAlternatives: [],
        inferenceTimeMs: 15,
      );

      // t = 0s -> Mobile Phone
      provider.handleContinuousMonitoringResult(phoneResult, nowOverride: baseTime);
      fakeTtsService.isSpeaking = false;
      expect(fakeTtsService.spokenTexts.last, equals('A mobile phone is in front of you.'));

      // t = 2s -> Keys (different object) appears
      provider.handleContinuousMonitoringResult(keysResult, nowOverride: baseTime.add(const Duration(seconds: 2)));
      fakeTtsService.isSpeaking = false;

      expect(fakeTtsService.spokenTexts.length, equals(2));
      expect(fakeTtsService.spokenTexts.last, equals('Keys are visible in front of you.'));
      expect(provider.currentIdentifiedClass, equals('keys'));
    });

    test('Disappearance Grace Period: brief drop (< 2s) does not clear tracking; drop > 2s allows new announcement', () {
      final baseTime = DateTime(2026, 10, 26, 12, 0, 0);

      const cupResult = ObjectClassificationResult(
        label: 'cup',
        displayName: 'Cup',
        confidence: 0.85,
        topAlternatives: [],
        inferenceTimeMs: 15,
      );

      // t = 0s -> Cup appears and announces
      provider.handleContinuousMonitoringResult(cupResult, nowOverride: baseTime);
      fakeTtsService.isSpeaking = false;
      expect(fakeTtsService.spokenTexts.length, equals(1));
      expect(fakeTtsService.spokenTexts.last, equals('A cup is visible in front of you.'));

      // t = 1.0s -> Drop below threshold (null or weak result)
      provider.handleContinuousMonitoringResult(null, nowOverride: baseTime.add(const Duration(seconds: 1)));
      // Tracked class should NOT be cleared yet because 1.0s < 2.0s grace period
      expect(provider.currentIdentifiedClass, equals('cup'));

      // t = 1.5s -> Cup reappears before grace period expires
      provider.handleContinuousMonitoringResult(cupResult, nowOverride: baseTime.add(const Duration(milliseconds: 1500)));
      // Should NOT re-announce (grace period prevented jitter)
      expect(fakeTtsService.spokenTexts.length, equals(1));

      // t = 4.0s -> Disappears for 2.5 seconds (> 2.0s grace period)
      provider.handleContinuousMonitoringResult(null, nowOverride: baseTime.add(const Duration(seconds: 4)));
      // Grace period exceeded: tracked state cleared quietly
      expect(provider.currentIdentifiedClass, isNull);
      expect(fakeTtsService.spokenTexts.length, equals(1)); // Stay quiet on disappearance

      // t = 5.0s -> Cup appears again after being gone
      provider.handleContinuousMonitoringResult(cupResult, nowOverride: baseTime.add(const Duration(seconds: 5)));
      fakeTtsService.isSpeaking = false;
      // Reappearance after full disappearance triggers a fresh announcement!
      expect(fakeTtsService.spokenTexts.length, equals(2));
      expect(fakeTtsService.spokenTexts.last, equals('A cup is visible in front of you.'));
    });

    test('Speech Overlap Protection: waits until TTS is free before announcing', () {
      final baseTime = DateTime(2026, 10, 26, 12, 0, 0);

      const laptopResult = ObjectClassificationResult(
        label: 'laptop',
        displayName: 'Laptop',
        confidence: 0.91,
        topAlternatives: [],
        inferenceTimeMs: 16,
      );

      // Simulate TTS already speaking another message
      fakeTtsService.isSpeaking = true;

      // Frame arrived while speaking
      provider.handleContinuousMonitoringResult(laptopResult, nowOverride: baseTime);
      expect(fakeTtsService.spokenTexts, isEmpty);
      expect(provider.currentIdentifiedClass, equals('laptop'));

      // Next frame arrives after TTS finishes speaking
      fakeTtsService.isSpeaking = false;
      provider.handleContinuousMonitoringResult(
        laptopResult,
        nowOverride: baseTime.add(const Duration(milliseconds: 500)),
      );

      // Now it announces safely without overlapping
      expect(fakeTtsService.spokenTexts.length, equals(1));
      expect(fakeTtsService.spokenTexts.first, equals('A laptop is in front of you.'));
    });

    test('Directional announcement when verified spatial direction is provided', () {
      final baseTime = DateTime(2026, 10, 26, 12, 0, 0);

      const personResult = ObjectClassificationResult(
        label: 'person',
        displayName: 'Person',
        confidence: 0.92,
        topAlternatives: [],
        inferenceTimeMs: 15,
      );

      provider.handleContinuousMonitoringResult(
        personResult,
        direction: SpatialDirection.left,
        nowOverride: baseTime,
      );

      expect(fakeTtsService.spokenTexts.length, equals(1));
      expect(fakeTtsService.spokenTexts.first, equals('A person is on your left.'));
      expect(fakeTtsService.spokenTexts.first, isNot(contains('%')));
    });

    test('Clean Stop: stopContinuousMonitoring resets state cleanly', () async {
      final baseTime = DateTime(2026, 10, 26, 12, 0, 0);

      const chairResult = ObjectClassificationResult(
        label: 'chair',
        displayName: 'Chair',
        confidence: 0.82,
        topAlternatives: [],
        inferenceTimeMs: 15,
      );

      await provider.startContinuousMonitoring();
      expect(provider.isContinuousMonitoring, isTrue);

      provider.handleContinuousMonitoringResult(chairResult, nowOverride: baseTime);
      expect(provider.currentIdentifiedClass, equals('chair'));

      await provider.stopContinuousMonitoring();
      expect(provider.isContinuousMonitoring, isFalse);
      expect(provider.currentIdentifiedClass, isNull);
      expect(provider.lastAnnouncementTime, isNull);
      expect(provider.currentObjectFirstSeen, isNull);
      expect(provider.currentObjectLastSeen, isNull);
    });
  });

  group('SceneDescriptionService Spatial Synthesis Tests', () {
    late SceneDescriptionService sceneService;

    setUp(() {
      sceneService = SceneDescriptionService();
    });

    test('Single object directly ahead formats natural description', () async {
      final boxes = [
        DetectedObjectBox(label: 'laptop', confidence: 0.88, left: 0.35, top: 0.4, right: 0.65, bottom: 0.7),
      ];
      final desc = await sceneService.describeScene('', fallbackBoxes: boxes);
      expect(desc, equals('A laptop is directly in front of you.'));
    });

    test('Two objects evaluate relative horizontal position', () async {
      final boxes = [
        DetectedObjectBox(label: 'laptop', confidence: 0.90, left: 0.3, top: 0.4, right: 0.5, bottom: 0.7),
        DetectedObjectBox(label: 'bottle', confidence: 0.85, left: 0.7, top: 0.4, right: 0.85, bottom: 0.75),
      ];
      final desc = await sceneService.describeScene('', fallbackBoxes: boxes);
      expect(desc, contains('laptop'));
      expect(desc, contains('bottle'));
      expect(desc, contains('on its right'));
    });

    test('Compound scene with table, laptop, bottle and chair formats rich spatial summary', () async {
      final boxes = [
        DetectedObjectBox(label: 'laptop', confidence: 0.92, left: 0.35, top: 0.4, right: 0.65, bottom: 0.7),
        DetectedObjectBox(label: 'bottle', confidence: 0.84, left: 0.7, top: 0.45, right: 0.85, bottom: 0.75),
        DetectedObjectBox(label: 'table', confidence: 0.88, left: 0.1, top: 0.4, right: 0.9, bottom: 0.85),
        DetectedObjectBox(label: 'chair', confidence: 0.80, left: 0.2, top: 0.15, right: 0.45, bottom: 0.45),
      ];
      final desc = await sceneService.describeScene('', fallbackBoxes: boxes);
      expect(desc, contains('laptop is directly in front of you on the table'));
      expect(desc, contains('bottle'));
      expect(desc, contains('chair is visible behind the table'));
    });
  });
}
