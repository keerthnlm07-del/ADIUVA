import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/core/services/voice_response_localizer.dart';
import 'package:adiuva/core/services/stt_service.dart';
import 'package:adiuva/core/services/tts_service.dart';
import 'package:adiuva/features/speech_assistance/presentation/provider/global_voice_control_provider.dart';

class FakeTtsService extends ChangeNotifier implements TtsService {
  String? lastSpokenText;
  String? lastLanguage;
  Function()? completionListener;
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text) async {
    lastSpokenText = text;
    _isSpeaking = true;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    lastLanguage = languageCode;
  }

  @override
  void setCompletionListener(Function() onComplete) {
    completionListener = onComplete;
  }

  @override
  void addCompletionListener(Function() onComplete) {
    completionListener = onComplete;
  }

  @override
  void removeCompletionListener(Function() onComplete) {}

  void triggerCompletion() {
    _isSpeaking = false;
    notifyListeners();
    completionListener?.call();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSttService implements SttService {
  bool isCurrentlyListening = false;
  String? activeLocale;

  @override
  bool get isInitialized => true;

  @override
  bool get isListening => isCurrentlyListening;

  @override
  String get lastWords => '';

  @override
  String? get errorMessage => null;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required Function onResult,
    required Function() onComplete,
    String? localeId,
  }) async {
    isCurrentlyListening = true;
    activeLocale = localeId;
  }

  @override
  Future<void> stopListening() async {
    isCurrentlyListening = false;
  }

  @override
  Future<void> cancelListening() async {
    isCurrentlyListening = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageCommandParser Tests', () {
    test('Parses direct English language switch commands', () {
      expect(LanguageCommandParser.parseTargetLanguage('change language to english'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('change language to hindi'), equals('hi'));
      expect(LanguageCommandParser.parseTargetLanguage('change language to kannada'), equals('kn'));
      expect(LanguageCommandParser.parseTargetLanguage('change language to telugu'), equals('te'));
      expect(LanguageCommandParser.parseTargetLanguage('change language to tamil'), equals('ta'));
    });

    test('Parses short switch commands', () {
      expect(LanguageCommandParser.parseTargetLanguage('switch to english'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('switch to hindi'), equals('hi'));
      expect(LanguageCommandParser.parseTargetLanguage('switch to kannada'), equals('kn'));
      expect(LanguageCommandParser.parseTargetLanguage('switch to telugu'), equals('te'));
      expect(LanguageCommandParser.parseTargetLanguage('switch to tamil'), equals('ta'));
    });

    test('Parses bidirectional language switching in regional scripts', () {
      // English in regional native scripts
      expect(LanguageCommandParser.parseTargetLanguage('இங்கிலீஷ்'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('ஆங்கிலம்'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('இங்கிலீஷ் மாற்று'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('ఇంగ్లీష్'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('ఇంగ్లీష్ కి మార్చు'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('ಇಂಗ್ಲಿಷ್'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('ಇಂಗ್ಲಿಷ್ಗೆ ಬದಲಾಯಿಸಿ'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('अंग्रेजी'), equals('en'));
      expect(LanguageCommandParser.parseTargetLanguage('अंग्रेजी में बदलो'), equals('en'));

      // Regional languages from English/regional scripts
      expect(LanguageCommandParser.parseTargetLanguage('తెలుగులో మార్చు'), equals('te'));
      expect(LanguageCommandParser.parseTargetLanguage('தமிழுக்கு மாற்று'), equals('ta'));
      expect(LanguageCommandParser.parseTargetLanguage('ಕನ್ನಡಕ್ಕೆ ಬದಲಾಯಿಸಿ'), equals('kn'));
      expect(LanguageCommandParser.parseTargetLanguage('हिंदी में बदलो'), equals('hi'));
    });

    test('Parses code-mixed Hinglish / Tenglish / Tanglish / Kanglish commands', () {
      expect(LanguageCommandParser.parseTargetLanguage('hindi me badlo'), equals('hi'));
      expect(LanguageCommandParser.parseTargetLanguage('telugu language ki marchu'), equals('te'));
      expect(LanguageCommandParser.parseTargetLanguage('tamil mozhi ku maathu'), equals('ta'));
      expect(LanguageCommandParser.parseTargetLanguage('kannada bhashe ge badalisi'), equals('kn'));
      expect(LanguageCommandParser.parseTargetLanguage('english me change karo'), equals('en'));
    });

    test('Parses cross-script native tokens from regional STT engines across all language pairs', () {
      // Telugu STT transcribing cross-language commands
      expect(LanguageCommandParser.parseTargetLanguage('చేంజ్ లాంగ్వేజ్ టు తమిళ'), equals('ta'));
      expect(LanguageCommandParser.parseTargetLanguage('చేంజ్ లాంగ్వೇజ్ టు హిందీ'), equals('hi'));
      expect(LanguageCommandParser.parseTargetLanguage('చేంజ్ లాంగ్వేజ్ టు కన్నడ'), equals('kn'));
      expect(LanguageCommandParser.parseTargetLanguage('చేంజ్ లాంగ్వేజ్ టు ఇంగ్లీష్'), equals('en'));

      // Tamil STT transcribing cross-language commands
      expect(LanguageCommandParser.parseTargetLanguage('சேஞ்ச் லாங்குவேஜ் டு தெலுகு'), equals('te'));
      expect(LanguageCommandParser.parseTargetLanguage('சேஞ்ச் லாங்குவேஜ் டு ஹிந்தி'), equals('hi'));
      expect(LanguageCommandParser.parseTargetLanguage('சேஞ்ச் லாங்குவேஜ் டு கன்னடா'), equals('kn'));
      expect(LanguageCommandParser.parseTargetLanguage('சேஞ்ச் லாங்குவேஜ் டு இங்கிலீஷ்'), equals('en'));

      // Kannada STT transcribing cross-language commands
      expect(LanguageCommandParser.parseTargetLanguage('ಚೇಂಜ್ ಲ್ಯಾಂಗ್ವೇಜ್ ಟು ತಮಿಳು'), equals('ta'));
      expect(LanguageCommandParser.parseTargetLanguage('ಚೇಂಜ್ ಲ್ಯಾಂಗ್ವೇಜ್ ಟು ತೆಲುಗು'), equals('te'));
      expect(LanguageCommandParser.parseTargetLanguage('ಚೇಂಜ್ ಲ್ಯಾಂಗ್ವೇಜ್ ಟು ಹಿಂದಿ'), equals('hi'));
      expect(LanguageCommandParser.parseTargetLanguage('ಚೇಂಜ್ ಲ್ಯಾಂಗ್ವೇಜ್ ಟು ಇಂಗ್ಲಿಷ್'), equals('en'));

      // Hindi STT transcribing cross-language commands
      expect(LanguageCommandParser.parseTargetLanguage('चेंज लैंग्वेज टू तमिल'), equals('ta'));
      expect(LanguageCommandParser.parseTargetLanguage('चेंज लैंग्वेज टू तेलुगु'), equals('te'));
      expect(LanguageCommandParser.parseTargetLanguage('चेंज लैंग्वेज टू कन्नड़'), equals('kn'));
      expect(LanguageCommandParser.parseTargetLanguage('चेंज लैंग्वेज टू इंग्लिश'), equals('en'));
    });

    test('Parses single word language commands', () {
      expect(LanguageCommandParser.parseTargetLanguage('tamil'), equals('ta'));
      expect(LanguageCommandParser.parseTargetLanguage('தமிழ்'), equals('ta'));
      expect(LanguageCommandParser.parseTargetLanguage('telugu'), equals('te'));
      expect(LanguageCommandParser.parseTargetLanguage('తెలుగు'), equals('te'));
      expect(LanguageCommandParser.parseTargetLanguage('kannada'), equals('kn'));
      expect(LanguageCommandParser.parseTargetLanguage('ಕನ್ನಡ'), equals('kn'));
      expect(LanguageCommandParser.parseTargetLanguage('hindi'), equals('hi'));
      expect(LanguageCommandParser.parseTargetLanguage('हिन्दी'), equals('hi'));
      expect(LanguageCommandParser.parseTargetLanguage('english'), equals('en'));
    });

    test('Returns null for unrelated navigation or feature commands', () {
      expect(LanguageCommandParser.parseTargetLanguage('open visual assistance'), isNull);
      expect(LanguageCommandParser.parseTargetLanguage('go home'), isNull);
      expect(LanguageCommandParser.parseTargetLanguage('help'), isNull);
    });
  });

  group('Noise & Filler Word Filtering Tests', () {
    late FakeSttService fakeStt;
    late FakeTtsService fakeTts;
    late GlobalVoiceControlProvider provider;

    setUp(() {
      fakeStt = FakeSttService();
      fakeTts = FakeTtsService();
      provider = GlobalVoiceControlProvider(
        sttService: fakeStt,
        ttsService: fakeTts,
      );
    });

    test('Identifies empty, short, and filler noise transcripts correctly', () {
      expect(provider.isNoiseOrFiller(''), isTrue);
      expect(provider.isNoiseOrFiller('   '), isTrue);
      expect(provider.isNoiseOrFiller('uh'), isTrue);
      expect(provider.isNoiseOrFiller('mm'), isTrue);
      expect(provider.isNoiseOrFiller('ah'), isTrue);
      expect(provider.isNoiseOrFiller('okay'), isTrue);
      expect(provider.isNoiseOrFiller('ha'), isTrue);
      expect(provider.isNoiseOrFiller('um'), isTrue);
      expect(provider.isNoiseOrFiller('ab'), isTrue); // <=2 chars non-command
    });

    test('Does not classify valid voice commands or language switches as noise', () {
      expect(provider.isNoiseOrFiller('open ocr'), isFalse);
      expect(provider.isNoiseOrFiller('go home'), isFalse);
      expect(provider.isNoiseOrFiller('sign in with google'), isFalse);
      expect(provider.isNoiseOrFiller('english'), isFalse);
      expect(provider.isNoiseOrFiller('hi'), isTrue); // 'hi' filler
      expect(provider.isNoiseOrFiller('hindi'), isFalse);
      expect(provider.isNoiseOrFiller('இங்கிலீஷ்'), isFalse);
    });
  });

  group('VoiceResponseLocalizer Tests', () {
    test('Provides single welcome prompt per language', () {
      final welcomeEn = VoiceResponseLocalizer.getStartupWelcome('en');
      final welcomeTa = VoiceResponseLocalizer.getStartupWelcome('ta');
      expect(welcomeEn, contains('Welcome to ADIUVA'));
      expect(welcomeTa, contains('வரவேற்கிறோம்'));
    });

    test('Silence yields null to ensure quiet auto-restarts without nagging', () {
      expect(VoiceResponseLocalizer.getSilencePrompt('en', 1), isNull);
      expect(VoiceResponseLocalizer.getSilencePrompt('en', 2), isNull);
      expect(VoiceResponseLocalizer.getSilencePrompt('en', 3), isNull);
    });

    test('Provides concise help text with essential navigation options', () {
      final helpEn = VoiceResponseLocalizer.getHelpText('en');
      expect(helpEn, contains('Sign In'));
      expect(helpEn, contains('Sign Up'));
      expect(helpEn, contains('Change Language'));
      expect(helpEn, contains('Visual Assistance'));
      expect(helpEn, contains('Go Home'));
    });

    test('Provides subtle hint for repeatedly unrecognized commands', () {
      expect(VoiceResponseLocalizer.unrecognizedSubtleHint('en'), contains('You can say Help for available commands.'));
      expect(VoiceResponseLocalizer.unrecognizedSubtleHint('hi'), contains('हेल्प बोल सकते हैं'));
      expect(VoiceResponseLocalizer.unrecognizedSubtleHint('te'), contains('హెల్ప్ అని చెప్పవచ్చు'));
      expect(VoiceResponseLocalizer.unrecognizedSubtleHint('ta'), contains('Help என்று சொல்லலாம்'));
      expect(VoiceResponseLocalizer.unrecognizedSubtleHint('kn'), contains('Help ಎಂದು ಹೇಳಬಹುದು'));
    });

    test('Provides language changed confirmation in target language with dual script formatting', () {
      expect(VoiceResponseLocalizer.getLanguageChangedConfirmation('ta'), contains('தமிழுக்கு'));
      expect(VoiceResponseLocalizer.getLanguageChangedConfirmation('ta'), contains('Mozhiyai Tamilukku maatriyullen'));
      expect(VoiceResponseLocalizer.getLanguageChangedConfirmation('te'), contains('తెలుగు'));
      expect(VoiceResponseLocalizer.getLanguageChangedConfirmation('kn'), contains('ಕನ್ನಡ'));
      expect(VoiceResponseLocalizer.getLanguageChangedConfirmation('hi'), contains('हिंदी'));
      expect(VoiceResponseLocalizer.getLanguageChangedConfirmation('en'), contains('English'));
    });
  });

  group('Multilingual Conversational System Tests', () {
    test('Resolves Layer 2 Conversational Phrases across English, Tamil, Telugu, and Kannada', () {
      // Basic Conversation Greeting
      final greetingEn = VoiceResponseLocalizer.resolveConversationalPhrase('hello', 'en');
      final greetingTa = VoiceResponseLocalizer.resolveConversationalPhrase('vanakkam', 'ta');
      final greetingTe = VoiceResponseLocalizer.resolveConversationalPhrase('namaskaram', 'te');
      final greetingKn = VoiceResponseLocalizer.resolveConversationalPhrase('namaskara', 'kn');

      expect(greetingEn?.intent, equals('BASIC_CONVERSATION_GREETING'));
      expect(greetingTa?.intent, equals('BASIC_CONVERSATION_GREETING'));
      expect(greetingTe?.intent, equals('BASIC_CONVERSATION_GREETING'));
      expect(greetingKn?.intent, equals('BASIC_CONVERSATION_GREETING'));

      // Basic Needs - Hungry
      final hungryEn = VoiceResponseLocalizer.resolveConversationalPhrase('i am hungry', 'en');
      final hungryTa = VoiceResponseLocalizer.resolveConversationalPhrase('enakku pasikkiradhu', 'ta');
      final hungryTe = VoiceResponseLocalizer.resolveConversationalPhrase('naaku aakaligaa undhi', 'te');
      final hungryKn = VoiceResponseLocalizer.resolveConversationalPhrase('nanage hasivaagide', 'kn');

      expect(hungryEn?.intent, equals('BASIC_NEEDS_HUNGRY'));
      expect(hungryTa?.intent, equals('BASIC_NEEDS_HUNGRY'));
      expect(hungryTe?.intent, equals('BASIC_NEEDS_HUNGRY'));
      expect(hungryKn?.intent, equals('BASIC_NEEDS_HUNGRY'));
    });

    test('Formats UI display string with Native script ON TOP and Transliteration UNDERNEATH', () {
      final phrase = VoiceResponseLocalizer.resolveConversationalPhrase('i am hungry', 'en');
      expect(phrase, isNotNull);

      final taDisplay = phrase!.getDisplayString('ta');
      final lines = taDisplay.split('\n');
      expect(lines.length, equals(2));
      expect(lines[0], contains('உங்களுக்கு பசிக்கிறது')); // Native script on TOP
      expect(lines[1], contains('Ungalukku pasikkiradhu')); // Transliteration UNDERNEATH

      final taTts = phrase.getTtsString('ta');
      expect(taTts, equals('உங்களுக்கு பசிக்கிறது என்பதை புரிகிறேன். உணவு நினைவூட்டல் அமைக்கவா அல்லது கேர்கிவரை அழைக்கவா?'));
    });
  });

  group('GlobalVoiceControlProvider Lifecycle Tests', () {
    late FakeSttService fakeStt;
    late FakeTtsService fakeTts;
    late GlobalVoiceControlProvider provider;

    setUp(() {
      fakeStt = FakeSttService();
      fakeTts = FakeTtsService();
      provider = GlobalVoiceControlProvider(
        sttService: fakeStt,
        ttsService: fakeTts,
      );
    });

    test('Initializes state correctly', () {
      expect(provider.state, equals(GlobalVoiceState.idle));
      expect(provider.isAutoVoiceEnabled, isTrue);
      expect(provider.isYieldedToFeature, isFalse);
    });

    test('Triggers language switch safely and updates locale', () async {
      await provider.changeLanguage('ta');

      expect(provider.currentLanguageCode, equals('ta'));
      expect(fakeTts.lastLanguage, equals('ta-IN'));
      expect(fakeTts.lastSpokenText, contains('தமிழுக்கு'));
    });

    test('speakConfirmation speaks ONLY Line 1 (Native script) for single-pass TTS playback', () async {
      const dualScriptText = 'మీ ప్రస్తుత స్థానం Kuppam, Chittoor, Andhra Pradesh, India.\nMee prastuta sthaanam Kuppam, Chittoor, Andhra Pradesh, India.';
      await provider.speakConfirmation(dualScriptText);

      expect(provider.lastTtsOutput, equals(dualScriptText)); // Retains dual representation for UI
      expect(fakeTts.lastSpokenText, equals('మీ ప్రస్తుత స్థానం Kuppam, Chittoor, Andhra Pradesh, India.')); // Speaks Line 1 ONLY
    });

    test('formatLocationResponse formats single line for English and dual representation for regional languages', () {
      final locEn = VoiceResponseLocalizer.formatLocationResponse('en', 'Kuppam, Chittoor, Andhra Pradesh, India');
      expect(locEn.contains('\n'), isFalse);
      expect(locEn, equals('Your current location is Kuppam, Chittoor, Andhra Pradesh, India.'));

      final locTe = VoiceResponseLocalizer.formatLocationResponse('te', 'Kuppam, Chittoor, Andhra Pradesh, India');
      final linesTe = locTe.split('\n');
      expect(linesTe.length, equals(2));
      expect(linesTe[0], contains('మీ ప్రస్తుత స్థానం'));
      expect(linesTe[1], contains('Mee prastuta sthaanam'));
    });
  });
}
