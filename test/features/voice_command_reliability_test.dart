import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/features/speech_assistance/data/datasources/voice_action_registry.dart';
import 'package:adiuva/features/speech_assistance/domain/entities/voice_action.dart';

void main() {
  group('Command Recognition Reliability Test Suite', () {
    late VoiceActionRegistry registry;

    setUp(() {
      registry = VoiceActionRegistry();
      registry.registerActions([
        const VoiceAction(
          id: 'open_visual_assistance',
          label: 'Visual Assistance',
          screenContext: 'home',
          aliases: ['open visual assistance', 'visual assistance', 'visual mode', 'vision', 'open vision'],
        ),
        const VoiceAction(
          id: 'open_hearing_assistance',
          label: 'Hearing Assistance',
          screenContext: 'home',
          aliases: ['open hearing assistance', 'hearing assistance', 'hearing mode'],
        ),
        const VoiceAction(
          id: 'open_cognitive_assistance',
          label: 'Cognitive Assistance',
          screenContext: 'home',
          aliases: ['open cognitive assistance', 'cognitive assistance', 'cognitive mode'],
        ),
        const VoiceAction(
          id: 'open_physical_assistance',
          label: 'Physical Assistance',
          screenContext: 'home',
          aliases: ['open physical assistance', 'physical assistance', 'physical mode'],
        ),
        const VoiceAction(
          id: 'open_normal_user',
          label: 'Normal User Suite',
          screenContext: 'home',
          aliases: ['open normal user', 'normal user', 'normal mode'],
        ),
        const VoiceAction(
          id: 'object_detection',
          label: 'Object Detection',
          screenContext: 'visual_assistance',
          aliases: ['open object detection', 'object detection'],
        ),
        const VoiceAction(
          id: 'ocr',
          label: 'Read Text',
          screenContext: 'visual_assistance',
          aliases: ['open ocr', 'ocr', 'read text'],
        ),
        const VoiceAction(
          id: 'start_reading',
          label: 'Start Reading',
          screenContext: 'visual_assistance',
          aliases: ['start', 'start reading'],
        ),
        const VoiceAction(
          id: 'pause_reading',
          label: 'Pause Reading',
          screenContext: 'visual_assistance',
          aliases: ['pause', 'pause reading'],
        ),
        const VoiceAction(
          id: 'resume_reading',
          label: 'Resume Reading',
          screenContext: 'visual_assistance',
          aliases: ['resume', 'resume reading'],
        ),
        const VoiceAction(
          id: 'next_page',
          label: 'Next Page',
          screenContext: 'visual_assistance',
          aliases: ['next page', 'next'],
        ),
        const VoiceAction(
          id: 'previous_page',
          label: 'Previous Page',
          screenContext: 'visual_assistance',
          aliases: ['previous page', 'previous'],
        ),
      ]);
    });

    final Map<String, String> testCases = {
      "Open Visual Assistance": "open_visual_assistance",
      "open visual assistance": "open_visual_assistance",
      "Open Visual Assistance.": "open_visual_assistance",
      "Go Home": "go_home",
      "Open Hearing Assistance": "open_hearing_assistance",
      "Open Cognitive Assistance": "open_cognitive_assistance",
      "Open Physical Assistance": "open_physical_assistance",
      "Open Normal User": "open_normal_user",
      "Open Object Detection": "object_detection",
      "Open OCR": "ocr",
      "Start": "start_reading",
      "Pause": "pause_reading",
      "Resume": "resume_reading",
      "Visual Assistance": "open_visual_assistance",
      "vision": "open_visual_assistance",
      "Next page": "next_page",
      "Previous page": "previous_page",
    };

    testCases.forEach((transcript, expectedActionId) {
      test('Transcript "$transcript" resolves to actionId "$expectedActionId"', () {
        // Evaluate context depending on test case type
        String screenContext = 'home';
        if (expectedActionId == 'object_detection' ||
            expectedActionId == 'ocr' ||
            expectedActionId == 'start_reading' ||
            expectedActionId == 'pause_reading' ||
            expectedActionId == 'resume_reading' ||
            expectedActionId == 'next_page' ||
            expectedActionId == 'previous_page') {
          screenContext = 'visual_assistance';
        }

        final match = registry.resolveAction(
          rawTranscript: transcript,
          currentScreenContext: screenContext,
        );

        expect(match, isNotNull, reason: 'Expected transcript "$transcript" to match an action');
        expect(match!.action.id, equals(expectedActionId));
      });
    });

    test('Welcome back greeting does not trigger go_back action', () {
      final match = registry.resolveAction(
        rawTranscript: 'Welcome back Kitty. Voice control is active.',
        currentScreenContext: 'home',
      );
      expect(match, isNull, reason: 'Welcome greeting must not match go_back action');
    });

    bool simulateEchoCheck({
      required String ttsPrompt,
      required String transcript,
      required bool isActivelySpeaking,
    }) {
      final cleanTts = ttsPrompt
          .replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '')
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final clean = transcript
          .replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '')
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final isExactMatch = cleanTts == clean;
      final lengthRatio = cleanTts.isNotEmpty ? clean.length / cleanTts.length : 0.0;

      final bool isVerbatimOrDominantEcho = isExactMatch ||
          (cleanTts.length >= 4 && clean.contains(cleanTts)) ||
          (clean.length >= 4 && cleanTts.contains(clean) && lengthRatio >= 0.70);

      final bool isInterrupt = clean == 'stop' || clean == 'cancel' || clean == 'quiet' || clean == 'hush';
      final bool isActivePlaybackLeak = isActivelySpeaking && cleanTts.contains(clean) && !isInterrupt;

      return isVerbatimOrDominantEcho || isActivePlaybackLeak;
    }

    test('Echo guard simulation: suggested command "Open Visual Assistance" is NOT an echo after help prompt', () {
      final isEcho = simulateEchoCheck(
        ttsPrompt: 'You can say Sign In, Sign Up, Change Language, Open Visual Assistance, Open Hearing Assistance, Open Cognitive Assistance, Open Physical Assistance, Open Normal User, or Go Home.',
        transcript: 'Open Visual Assistance',
        isActivelySpeaking: false,
      );

      expect(isEcho, isFalse, reason: 'Legitimate user command "Open Visual Assistance" must not be dropped as an echo after help message finishes');
    });

    test('Echo guard simulation: active playback leak of TTS words IS ignored while TTS is actively speaking', () {
      final isEcho = simulateEchoCheck(
        ttsPrompt: 'Say Help for a list of available commands.',
        transcript: 'available commands',
        isActivelySpeaking: true,
      );

      expect(isEcho, isTrue, reason: 'Microphone pickup of loudspeaker speech during active playback must be flagged as leak');
    });
  });
}
