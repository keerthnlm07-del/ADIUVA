import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/features/sign_language/data/datasources/isl_tflite_service.dart';
import 'package:adiuva/features/sign_language/data/registries/sign_language_phrase_registry.dart';
import 'package:adiuva/features/sign_language/data/services/sign_language_animation_service.dart';
import 'package:adiuva/features/sign_language/domain/entities/isl_avatar_character.dart';
import 'package:adiuva/features/sign_language/presentation/provider/sign_language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('IslTfliteService Stage 1 TFLite Model Tests', () {
    late IslTfliteService service;

    setUp(() {
      service = IslTfliteService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('Initial confidence threshold defaults to 0.70', () {
      expect(service.confidenceThreshold, equals(0.70));
    });

    test('Configurable confidence threshold updates correctly', () {
      service.confidenceThreshold = 0.80;
      expect(service.confidenceThreshold, equals(0.80));
    });

    test('Resetting temporal buffer clears historical state cleanly', () {
      service.resetTemporalBuffer();
      expect(service.confidenceThreshold, equals(0.70));
    });

    test('inferFromFeatures returns null for invalid dimension vector', () {
      final invalid = [0.1, 0.2, 0.3];
      expect(service.inferFromFeatures(invalid), isNull);
    });

    test('inferFromFeatures returns null when model is not initialized or below threshold', () {
      final dummy = List<double>.filled(20, 0.0);
      expect(service.inferFromFeatures(dummy), isNull);
    });
  });

  group('SignLanguagePhraseRegistry Canonical Vocabulary Tests', () {
    test('Contains registered canonical ISL phrases (33 phrases including alphabet A-D)', () {
      expect(SignLanguagePhraseRegistry.phrases.length, equals(33));
    });

    test('Contains alphabet signs (A, B, C, D)', () {
      final phraseIds = SignLanguagePhraseRegistry.phrases.map((p) => p.id).toSet();
      expect(phraseIds.contains('A'), isTrue);
      expect(phraseIds.contains('B'), isTrue);
      expect(phraseIds.contains('C'), isTrue);
      expect(phraseIds.contains('D'), isTrue);
    });

    test('Contains all required assistive phrases (Help, I need help, Emergency, Location, Caregiver, Water, Medicine, etc.)', () {
      final phraseIds = SignLanguagePhraseRegistry.phrases.map((p) => p.id).toSet();
      expect(phraseIds.contains('hello'), isTrue);
      expect(phraseIds.contains('good_morning'), isTrue);

      expect(phraseIds.contains('how_are_you'), isTrue);
      expect(phraseIds.contains('thank_you'), isTrue);
      expect(phraseIds.contains('please'), isTrue);
      expect(phraseIds.contains('sorry'), isTrue);
      expect(phraseIds.contains('yes'), isTrue);
      expect(phraseIds.contains('no'), isTrue);
      expect(phraseIds.contains('help'), isTrue);
      expect(phraseIds.contains('i_need_help'), isTrue);
      expect(phraseIds.contains('stop'), isTrue);
      expect(phraseIds.contains('emergency'), isTrue);
      expect(phraseIds.contains('where_am_i'), isTrue);
      expect(phraseIds.contains('location'), isTrue);
      expect(phraseIds.contains('home'), isTrue);
      expect(phraseIds.contains('caregiver'), isTrue);
      expect(phraseIds.contains('call_caregiver'), isTrue);
      expect(phraseIds.contains('water'), isTrue);
      expect(phraseIds.contains('food'), isTrue);
      expect(phraseIds.contains('medicine'), isTrue);
      expect(phraseIds.contains('hospital'), isTrue);
      expect(phraseIds.contains('doctor'), isTrue);
      expect(phraseIds.contains('toilet'), isTrue);
      expect(phraseIds.contains('come'), isTrue);
      expect(phraseIds.contains('go'), isTrue);
      expect(phraseIds.contains('wait'), isTrue);
      expect(phraseIds.contains('i_understand'), isTrue);
      expect(phraseIds.contains('i_dont_understand'), isTrue);
      expect(phraseIds.contains('what_are_you_doing'), isTrue);
    });

    test('Normalizes text correctly (lowercase, trim, strip punctuation)', () {
      expect(SignLanguagePhraseRegistry.normalize('  Thank You!  '), equals('thank you'));
      expect(SignLanguagePhraseRegistry.normalize('HOW ARE YOU???'), equals('how are you'));
    });

    test('Finds phrase by exact phrase ID', () {
      final phrase = SignLanguagePhraseRegistry.findPhrase('hello');
      expect(phrase, isNotNull);
      expect(phrase!.animationName, equals('HELLO'));
    });

    test('Finds phrase by display text', () {
      final phrase = SignLanguagePhraseRegistry.findPhrase('Good morning');
      expect(phrase, isNotNull);
      expect(phrase!.animationName, equals('GOOD_MORNING'));
    });

    test('Finds phrase by regional language aliases (Hindi, Telugu, Tamil, Kannada)', () {
      final hindiThanks = SignLanguagePhraseRegistry.findPhrase('धन्यवाद');
      expect(hindiThanks, isNotNull);
      expect(hindiThanks!.id, equals('thank_you'));

      final teluguHelp = SignLanguagePhraseRegistry.findPhrase('సహాయం');
      expect(teluguHelp, isNotNull);
      expect(teluguHelp!.id, equals('help'));

      final tamilWater = SignLanguagePhraseRegistry.findPhrase('தண்ணீர்');
      expect(tamilWater, isNotNull);
      expect(tamilWater!.id, equals('water'));

      final kannadaHome = SignLanguagePhraseRegistry.findPhrase('ಮನೆ');
      expect(kannadaHome, isNotNull);
      expect(kannadaHome!.id, equals('home'));
    });

    test('Returns null for unregistered phrase', () {
      final phrase = SignLanguagePhraseRegistry.findPhrase('unsupported random phrase XYZ');
      expect(phrase, isNull);
    });
  });

  group('SignLanguageAnimationService Tests', () {
    late SignLanguageAnimationService animationService;

    setUp(() {
      animationService = SignLanguageAnimationService();
    });

    test('playPhrase sets activePhrase and returns true for valid registered phrase', () async {
      final success = await animationService.playPhrase('Good morning');
      expect(success, isTrue);
      expect(animationService.activePhrase, isNotNull);
      expect(animationService.activePhrase!.animationName, equals('GOOD_MORNING'));
      expect(animationService.isPlaying, isTrue);
    });

    test('playPhrase returns false and status message for unregistered phrase', () async {
      final success = await animationService.playPhrase('random unregistered phrase');
      expect(success, isFalse);
      expect(animationService.statusMessage, contains("don't have a sign"));
    });

    test('Pause, resume, and stop update playback state cleanly', () async {
      await animationService.playPhrase('Sorry');
      expect(animationService.isPlaying, isTrue);

      animationService.pause();
      expect(animationService.isPaused, isTrue);

      animationService.resume();
      expect(animationService.isPaused, isFalse);
      expect(animationService.isPlaying, isTrue);

      animationService.stop();
      expect(animationService.isPlaying, isFalse);
    });
  });

  group('SignLanguageProvider Two-Way Converter State Tests', () {
    late SignLanguageProvider provider;

    setUp(() {
      provider = SignLanguageProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial mode is signToText', () {
      expect(provider.currentMode, equals(SignLanguageMode.signToText));
    });

    test('setMode updates active mode cleanly', () {
      provider.setMode(SignLanguageMode.textToSign);
      expect(provider.currentMode, equals(SignLanguageMode.textToSign));
    });

    test('playPhraseByText sets feedback message for unsupported phrase', () async {
      await provider.playPhraseByText('Arbitrary unsupported sentence');
      expect(provider.feedbackMessage, contains('not currently supported'));
    });

    test('playPhraseByText selects phrase and updates feedback message', () async {
      await provider.playPhraseByText('Help');
      expect(provider.selectedPhrase?.id, equals('help'));
      expect(provider.feedbackMessage, isNotNull);
    });

    test('Avatar character selection switches between male and female models cleanly', () async {
      expect(provider.selectedCharacter.id, equals('male'));
      await provider.selectCharacter(IslAvatarCharacter.female);
      expect(provider.selectedCharacter.id, equals('female'));
      expect(provider.selectedCharacter.shortName, equals('Ananya'));
      expect(provider.hasSelectedAvatar, isTrue);

      await provider.selectCharacter(IslAvatarCharacter.male);
      expect(provider.selectedCharacter.id, equals('male'));
      expect(provider.selectedCharacter.shortName, equals('Aarav'));
    });

    test('Transcript history management (clearTranscript)', () {
      provider.clearTranscript();
      expect(provider.transcriptHistory, isEmpty);
      expect(provider.accumulatedTranscript, isEmpty);
    });
  });
}
