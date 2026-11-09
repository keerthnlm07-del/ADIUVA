import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/features/speech_assistance/domain/entities/voice_action.dart';
import 'package:adiuva/features/speech_assistance/data/datasources/voice_action_registry.dart';

void main() {
  group('VoiceActionRegistry Tests', () {
    late VoiceActionRegistry registry;

    setUp(() {
      registry = VoiceActionRegistry();
      registry.registerActions([
        const VoiceAction(
          id: 'start_reading',
          label: 'Start Reading',
          screenContext: 'visual_assistance',
          aliases: ['start', 'start reading', 'read aloud', 'play'],
        ),
        const VoiceAction(
          id: 'open_visual_assistance',
          label: 'Visual Assistance',
          screenContext: 'home',
          aliases: ['open visual assistance', 'visual assistance', 'open visual'],
        ),
      ]);
    });

    test('Resolves exact and short aliases like "start" on matching screen', () {
      final match = registry.resolveAction(
        rawTranscript: 'start',
        currentScreenContext: 'visual_assistance',
      );

      expect(match, isNotNull);
      expect(match!.action.id, equals('start_reading'));
    });

    test('Resolves global actions like "emergency" from any screen', () {
      final match = registry.resolveAction(
        rawTranscript: 'emergency',
        currentScreenContext: 'notes',
      );

      expect(match, isNotNull);
      expect(match!.action.id, equals('emergency_sos'));
    });

    test('Returns null when no action matches transcript', () {
      final match = registry.resolveAction(
        rawTranscript: 'unrelated random words',
        currentScreenContext: 'home',
      );

      expect(match, isNull);
    });

    test('Resolves WHERE_AM_I across English, Tamil, Telugu, Kannada, and Hindi variations', () {
      final matchSingleLocation = registry.resolveAction(rawTranscript: 'Location', currentScreenContext: 'home');
      final matchLocPlease = registry.resolveAction(rawTranscript: 'location please', currentScreenContext: 'home');
      final matchShowLoc = registry.resolveAction(rawTranscript: 'show location', currentScreenContext: 'home');
      final matchMyLoc = registry.resolveAction(rawTranscript: 'my location', currentScreenContext: 'home');
      final matchCurrLoc = registry.resolveAction(rawTranscript: 'current location', currentScreenContext: 'home');
      final matchTellLoc = registry.resolveAction(rawTranscript: 'tell me my location', currentScreenContext: 'home');
      final matchWhatLoc = registry.resolveAction(rawTranscript: 'what is my location', currentScreenContext: 'home');
      final matchEn = registry.resolveAction(rawTranscript: 'Where am I?', currentScreenContext: 'home');
      final matchTa = registry.resolveAction(rawTranscript: 'Naan engae irukkiren?', currentScreenContext: 'home');
      final matchTaScript = registry.resolveAction(rawTranscript: 'நான் எங்கே இருக்கிறேன்?', currentScreenContext: 'home');
      final matchTe = registry.resolveAction(rawTranscript: 'Nenu ekkada unnanu?', currentScreenContext: 'home');
      final matchTeScript = registry.resolveAction(rawTranscript: 'నేను ఎక్కడ ఉన్నాను?', currentScreenContext: 'home');
      final matchKn = registry.resolveAction(rawTranscript: 'Naanu elliddene?', currentScreenContext: 'home');
      final matchKnScript = registry.resolveAction(rawTranscript: 'ನಾನು ಎಲ್ಲಿದ್ದೇನೆ?', currentScreenContext: 'home');
      final matchHi = registry.resolveAction(rawTranscript: 'Main kahan hoon?', currentScreenContext: 'home');
      final matchHiScript = registry.resolveAction(rawTranscript: 'मैं कहाँ हूँ?', currentScreenContext: 'home');
      final matchHiSingle = registry.resolveAction(rawTranscript: 'मेरी लोकेशन', currentScreenContext: 'home');

      expect(matchSingleLocation?.action.id, equals('open_location'));
      expect(matchLocPlease?.action.id, equals('open_location'));
      expect(matchShowLoc?.action.id, equals('open_location'));
      expect(matchMyLoc?.action.id, equals('open_location'));
      expect(matchCurrLoc?.action.id, equals('open_location'));
      expect(matchTellLoc?.action.id, equals('open_location'));
      expect(matchWhatLoc?.action.id, equals('open_location'));
      expect(matchEn?.action.id, equals('open_location'));
      expect(matchTa?.action.id, equals('open_location'));
      expect(matchTaScript?.action.id, equals('open_location'));
      expect(matchTe?.action.id, equals('open_location'));
      expect(matchTeScript?.action.id, equals('open_location'));
      expect(matchKn?.action.id, equals('open_location'));
      expect(matchKnScript?.action.id, equals('open_location'));
      expect(matchHi?.action.id, equals('open_location'));
      expect(matchHiScript?.action.id, equals('open_location'));
      expect(matchHiSingle?.action.id, equals('open_location'));

      // Ensure false positives like 'relocation' are NOT matched
      final matchRelocation = registry.resolveAction(rawTranscript: 'relocation company', currentScreenContext: 'home');
      expect(matchRelocation, isNull);
    });

    test('Resolves GO_HOME across natural variants and regional code-switching', () {
      final match1 = registry.resolveAction(rawTranscript: 'Go home.', currentScreenContext: 'notes');
      final match2 = registry.resolveAction(rawTranscript: 'Please take me home.', currentScreenContext: 'notes');
      final match3 = registry.resolveAction(rawTranscript: 'I want to go home.', currentScreenContext: 'notes');
      final matchTa = registry.resolveAction(rawTranscript: 'Naan home-ku poganum.', currentScreenContext: 'notes');
      final matchTe = registry.resolveAction(rawTranscript: 'Nenu home ki vellali.', currentScreenContext: 'notes');
      final matchKn = registry.resolveAction(rawTranscript: 'Naanu home ge hogbeku.', currentScreenContext: 'notes');

      expect(match1?.action.id, equals('go_home'));
      expect(match2?.action.id, equals('go_home'));
      expect(match3?.action.id, equals('go_home'));
      expect(matchTa?.action.id, equals('go_home'));
      expect(matchTe?.action.id, equals('go_home'));
      expect(matchKn?.action.id, equals('go_home'));
    });

    test('Resolves OPEN_VISUAL_ASSISTANCE for polite requests and code-switching', () {
      final match1 = registry.resolveAction(rawTranscript: 'Open Visual Assistance.', currentScreenContext: 'home');
      final match2 = registry.resolveAction(rawTranscript: 'Please open Visual Assistance.', currentScreenContext: 'home');
      final match3 = registry.resolveAction(rawTranscript: 'Visual Assistance open pannunga.', currentScreenContext: 'home');

      expect(match1?.action.id, equals('open_visual_assistance'));
      expect(match2?.action.id, equals('open_visual_assistance'));
      expect(match3?.action.id, equals('open_visual_assistance'));
    });
  });
}
