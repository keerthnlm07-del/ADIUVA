import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/features/speech_assistance/data/voice_language_dataset/global_voice_intents.dart';
import 'package:adiuva/features/speech_assistance/data/voice_language_dataset/english_voice_phrases.dart';
import 'package:adiuva/features/speech_assistance/data/voice_language_dataset/telugu_voice_phrases.dart';
import 'package:adiuva/features/speech_assistance/data/voice_language_dataset/tamil_voice_phrases.dart';
import 'package:adiuva/features/speech_assistance/data/voice_language_dataset/kannada_voice_phrases.dart';
import 'package:adiuva/features/speech_assistance/data/voice_language_dataset/hindi_voice_phrases.dart';
import 'package:adiuva/features/speech_assistance/data/voice_language_dataset/mixed_language_phrases.dart';
import 'package:adiuva/features/speech_assistance/data/voice_language_dataset/voice_response_templates.dart';

void main() {
  group('Voice Language Dataset Integrity Tests', () {
    test('1. English Location dataset contains 20+ phrases mapping to open_location', () {
      final locationPhrases = EnglishVoicePhrases.phrasesByIntent[GlobalVoiceIntent.openLocation];
      expect(locationPhrases, isNotNull);
      expect(locationPhrases!.length, greaterThanOrEqualTo(20));
      expect(locationPhrases, contains('location'));
      expect(locationPhrases, contains('where am i'));
      expect(locationPhrases, contains('my location'));
      expect(locationPhrases, contains('current location'));
    });

    test('2. Telugu Location dataset contains 20+ verified native phrases + transliterations', () {
      final locationPhrases = TeluguVoicePhrases.phrasesByIntent[GlobalVoiceIntent.openLocation];
      expect(locationPhrases, isNotNull);
      expect(locationPhrases!.length, greaterThanOrEqualTo(20));

      final nativeList = locationPhrases.map((p) => p.native).toList();
      final transList = locationPhrases.map((p) => p.transliteration).toList();

      expect(nativeList, contains('స్థానం'));
      expect(nativeList, contains('నేను ఎక్కడ ఉన్నాను'));
      expect(nativeList, contains('నా లొకేషన్ చూపించు'));

      expect(transList, contains('sthaanam'));
      expect(transList, contains('nenu ekkada unnanu'));
      expect(transList, contains('naa location chupinchu'));

      // Verify NO unrelated terms like temple (ఆలయం), city (నగరం), address (అడ్రస్)
      expect(nativeList, isNot(contains('ఆలయం')));
      expect(nativeList, isNot(contains('నగరం')));
    });

    test('3. Tamil Location dataset contains 20+ verified native phrases + transliterations', () {
      final locationPhrases = TamilVoicePhrases.phrasesByIntent[GlobalVoiceIntent.openLocation];
      expect(locationPhrases, isNotNull);
      expect(locationPhrases!.length, greaterThanOrEqualTo(20));

      final nativeList = locationPhrases.map((p) => p.native).toList();
      final transList = locationPhrases.map((p) => p.transliteration).toList();

      expect(nativeList, contains('இருப்பிடம்'));
      expect(nativeList, contains('நான் எங்கே இருக்கிறேன்'));
      expect(transList, contains('iruppidam'));
      expect(transList, contains('naan engae irukkiren'));
    });

    test('4. Kannada Location dataset contains 20+ verified native phrases + transliterations', () {
      final locationPhrases = KannadaVoicePhrases.phrasesByIntent[GlobalVoiceIntent.openLocation];
      expect(locationPhrases, isNotNull);
      expect(locationPhrases!.length, greaterThanOrEqualTo(20));

      final nativeList = locationPhrases.map((p) => p.native).toList();
      final transList = locationPhrases.map((p) => p.transliteration).toList();

      expect(nativeList, contains('ಸ್ಥಳ'));
      expect(nativeList, contains('ನಾನು ಎಲ್ಲಿದ್ದೇನೆ'));
      expect(transList, contains('sthala'));
      expect(transList, contains('naanu elliddene'));
    });

    test('5. Hindi Location dataset contains 20+ verified native phrases + transliterations', () {
      final locationPhrases = HindiVoicePhrases.phrasesByIntent[GlobalVoiceIntent.openLocation];
      expect(locationPhrases, isNotNull);
      expect(locationPhrases!.length, greaterThanOrEqualTo(20));

      final nativeList = locationPhrases.map((p) => p.native).toList();
      final transList = locationPhrases.map((p) => p.transliteration).toList();

      expect(nativeList, contains('स्थान'));
      expect(nativeList, contains('मैं कहाँ हूँ'));
      expect(transList, contains('sthaan'));
      expect(transList, contains('main kahan hoon'));
    });

    test('6. Mixed-Language dataset contains code-switching phrases for major intents', () {
      final mixedLocation = MixedLanguagePhrases.phrasesByIntent[GlobalVoiceIntent.openLocation];
      expect(mixedLocation, isNotNull);
      expect(mixedLocation, contains('location చూపించు'));
      expect(mixedLocation, contains('location காட்டுங்க'));
      expect(mixedLocation, contains('location ತೋರಿಸು'));
      expect(mixedLocation, contains('location बताओ'));
    });

    test('7. Transliterations are same-language Latin script and NOT English translations', () {
      final tePair = TeluguVoicePhrases.phrasesByIntent[GlobalVoiceIntent.openLocation]!.firstWhere((p) => p.native == 'నేను ఎక్కడ ఉన్నాను');
      expect(tePair.transliteration, equals('nenu ekkada unnanu'));
      expect(tePair.transliteration, isNot(equals('Where am I')));

      final taPair = TamilVoicePhrases.phrasesByIntent[GlobalVoiceIntent.openLocation]!.firstWhere((p) => p.native == 'நான் எங்கே இருக்கிறேன்');
      expect(taPair.transliteration, equals('naan engae irukkiren'));
      expect(taPair.transliteration, isNot(equals('Where am I')));
    });

    test('8. Location address formatting removes raw plus codes, pin codes, and house numbers', () {
      const rawAddress = '#12-3/4, Q900+789, Kuppam, 517425, Chittoor, Andhra Pradesh, India';
      final cleaned = VoiceResponseTemplates.formatCleanLocationAddress(rawAddress);

      expect(cleaned, equals('Kuppam, Chittoor, Andhra Pradesh, India'));
      expect(cleaned, isNot(contains('Q900+789')));
      expect(cleaned, isNot(contains('517425')));
      expect(cleaned, isNot(contains('#12-3/4')));
    });

    test('9. Response template returns native script on Line 1 and transliteration on Line 2', () {
      final teResp = VoiceResponseTemplates.getLocationResponse(languageCode: 'te-IN', address: 'Kuppam, Chittoor');
      final lines = teResp.displayString.split('\n');

      expect(lines.length, equals(2));
      expect(lines[0], contains('మీ ప్రస్తుత స్థానం Kuppam, Chittoor.'));
      expect(lines[1], contains('Mee prastuta sthaanam Kuppam, Chittoor.'));

      // TTS speaks ONLY native script (Line 1)
      expect(teResp.ttsText, equals('మీ ప్రస్తుత స్థానం Kuppam, Chittoor.'));
    });

    test('10. Document Reader phrases exist across all 5 languages + transliterations + mixed language', () {
      final docEn = EnglishVoicePhrases.phrasesByIntent[GlobalVoiceIntent.documentReader];
      final docTe = TeluguVoicePhrases.phrasesByIntent[GlobalVoiceIntent.documentReader];
      final docTa = TamilVoicePhrases.phrasesByIntent[GlobalVoiceIntent.documentReader];
      final docKn = KannadaVoicePhrases.phrasesByIntent[GlobalVoiceIntent.documentReader];
      final docHi = HindiVoicePhrases.phrasesByIntent[GlobalVoiceIntent.documentReader];
      final docMix = MixedLanguagePhrases.phrasesByIntent[GlobalVoiceIntent.documentReader];

      expect(docEn, isNotNull);
      expect(docEn!.length, equals(20));
      expect(docEn, contains('document reader'));
      expect(docEn, contains('read this document'));

      expect(docTe, isNotNull);
      expect(docTe!.length, equals(20));
      expect(docTe.map((p) => p.native), contains('ఈ డాక్యుమెంట్ చదువు'));
      expect(docTe.map((p) => p.transliteration), contains('ee document chaduvu'));

      expect(docTa, isNotNull);
      expect(docTa!.length, equals(20));
      expect(docTa.map((p) => p.native), contains('இந்த ஆவணத்தை படி'));
      expect(docTa.map((p) => p.transliteration), contains('indha aavanathai padi'));

      expect(docKn, isNotNull);
      expect(docKn!.length, equals(20));
      expect(docKn.map((p) => p.native), contains('ಈ ದಾಖಲೆಯನ್ನು ಓದು'));
      expect(docKn.map((p) => p.transliteration), contains('ee daakhaleyannu odu'));

      expect(docHi, isNotNull);
      expect(docHi!.length, equals(20));
      expect(docHi.map((p) => p.native), contains('यह दस्तावेज पढ़ो'));
      expect(docHi.map((p) => p.transliteration), contains('yeh dastavez padho'));

      expect(docMix, isNotNull);
      expect(docMix!.length, equals(12));
      expect(docMix, contains('document reader open cheyyi'));
      expect(docMix, contains('this document padho'));
    });
  });
}
