import 'global_voice_intents.dart';

/// Mixed-Language / Code-Switching Voice Phrases Dataset for ADIUVA Global Voice Control
/// Handles natural user combinations of English keywords + regional language verbs/grammatical markers.
class MixedLanguagePhrases {
  static const Map<String, List<String>> phrasesByIntent = {
    // 1. LOCATION MIXED PHRASES
    GlobalVoiceIntent.openLocation: [
      'location చూపించు',
      'location காட்டுங்க',
      'location ತೋರಿಸು',
      'location बताओ',
      'location cheppu',
      'location sol',
      'location helu',
      'location dikhao',
      'where am i చెప్పు',
      'where am i சொல்',
      'where am i ಹೇಳು',
      'where am i बताओ',
      'current location చూపించు',
      'current location காட்டு',
      'current location ತೋರಿಸು',
      'current location बताओ',
      'location teruvu',
      'location thira',
      'location tere',
      'location kholo',
      'my location cheppu',
      'my location sol',
      'my location helu',
      'my location batao',
    ],

    // 2. GO HOME MIXED PHRASES
    GlobalVoiceIntent.goHome: [
      'home ki vellu',
      'home ku po',
      'home ge hogu',
      'home pe chalo',
      'home page ki vellu',
      'home thirai thira',
      'home putakke hogu',
      'home page par jao',
      'home chalo',
      'home vellali',
      'home poganum',
      'home hogbeku',
      'home jaana hai',
      'dashboard ki vellu',
      'dashboard ukku po',
      'dashboard ge hogu',
      'dashboard par jao',
      'take me home cheyyi',
      'take me home pannu',
      'take me home maadi',
    ],

    // 3. GO BACK MIXED PHRASES
    GlobalVoiceIntent.goBack: [
      'screen back vellu',
      'page back po',
      'screen back hogu',
      'page back jao',
      'previous page ki vellu',
      'previous page ukku po',
      'previous page ge hogu',
      'previous page par jao',
      'back vellali',
      'back poganum',
      'back hogbeku',
      'back jaana hai',
    ],

    // 4. EMERGENCY SOS MIXED PHRASES
    GlobalVoiceIntent.emergencySos: [
      'sos open cheyyi',
      'sos open pannu',
      'sos open maadi',
      'sos kholo',
      'emergency alert pampu',
      'emergency alert anuppu',
      'emergency alert kaluhisi',
      'emergency alert bhejo',
      'caregiver ki call cheyi',
      'caregiver ai alai',
      'caregiver ge kare maadi',
      'caregiver ko call karo',
      'sos button nokku',
      'sos button aluthu',
      'sos button otthi',
      'sos button dabao',
    ],

    // 5. VISUAL ASSISTANCE MIXED PHRASES
    GlobalVoiceIntent.openVisualAssistance: [
      'visual assistance open cheyyi',
      'visual assistance open pannu',
      'visual assistance open maadi',
      'visual assistance kholo',
      'visual assistant praarambhinchu',
      'visual assistant thodangu',
      'visual assistant praarambhisi',
      'visual assistant shuru karo',
      'vision mode teruvu',
      'vision mode thira',
      'vision mode tere',
      'vision mode kholo',
      'visual helper open cheyyi',
      'visual helper open pannu',
      'visual helper open maadi',
      'visual helper kholo',
    ],

    // 6. OBJECT DETECTION MIXED PHRASES
    GlobalVoiceIntent.objectDetection: [
      'object detection open cheyyi',
      'object detection open pannu',
      'object detection open maadi',
      'object detection kholo',
      'objects detect cheyi',
      'objects detect pannu',
      'objects detect maadi',
      'objects detect karo',
      'object detector teruvu',
      'object detector thira',
      'object detector tere',
      'object detector kholo',
    ],

    // 7. OCR MIXED PHRASES
    GlobalVoiceIntent.ocr: [
      'ocr text reader open cheyyi',
      'ocr text reader open pannu',
      'ocr text reader open maadi',
      'ocr text reader kholo',
      'text read cheyi',
      'text read pannu',
      'text read maadi',
      'text read karo',
      'ocr mode open cheyi',
      'ocr mode open pannu',
      'ocr mode open maadi',
      'ocr mode kholo',
    ],

    // 8. SCENE DESCRIPTION MIXED PHRASES
    GlobalVoiceIntent.sceneDescription: [
      'scene description open cheyyi',
      'scene description open pannu',
      'scene description open maadi',
      'scene description kholo',
      'describe surroundings cheyi',
      'describe surroundings pannu',
      'describe surroundings maadi',
      'describe surroundings karo',
    ],

    // 8B. DOCUMENT READER MIXED PHRASES
    GlobalVoiceIntent.documentReader: [
      'document reader open cheyyi',
      'document reader open pannu',
      'document reader open maadi',
      'document reader kholo',
      'this document chaduvu',
      'this document padi',
      'this document odu',
      'this document padho',
      'document read cheyi',
      'document read pannu',
      'document read maadi',
      'document read karo',
    ],

    // 9. PHYSICAL ASSISTANCE MIXED PHRASES
    GlobalVoiceIntent.openPhysicalAssistance: [
      'physical assistance open cheyyi',
      'physical assistance open pannu',
      'physical assistance open maadi',
      'physical assistance kholo',
      'physical mode teruvu',
      'physical mode thira',
      'physical mode tere',
      'physical mode kholo',
    ],

    // 10. COGNITIVE ASSISTANCE MIXED PHRASES
    GlobalVoiceIntent.openCognitiveAssistance: [
      'cognitive assistance open cheyyi',
      'cognitive assistance open pannu',
      'cognitive assistance open maadi',
      'cognitive assistance kholo',
      'cognitive mode teruvu',
      'cognitive mode thira',
      'cognitive mode tere',
      'cognitive mode kholo',
    ],

    // 11. HEARING ASSISTANCE MIXED PHRASES
    GlobalVoiceIntent.openHearingAssistance: [
      'hearing assistance open cheyyi',
      'hearing assistance open pannu',
      'hearing assistance open maadi',
      'hearing assistance kholo',
      'live captions open cheyyi',
      'live captions open pannu',
      'live captions open maadi',
      'live captions kholo',
    ],

    // 12. SIGN LANGUAGE MIXED PHRASES
    GlobalVoiceIntent.openSignLanguage: [
      'sign language translator open cheyyi',
      'sign language translator open pannu',
      'sign language translator open maadi',
      'sign language translator kholo',
      'sign detection open cheyyi',
      'sign detection open pannu',
      'sign detection open maadi',
      'sign detection kholo',
    ],

    // 13. TRANSLATOR MIXED PHRASES
    GlobalVoiceIntent.openTranslator: [
      'translator open cheyyi',
      'translator open pannu',
      'translator open maadi',
      'translator kholo',
      'voice translator open cheyyi',
      'voice translator open pannu',
      'voice translator open maadi',
      'voice translator kholo',
    ],

    // 14. TASKS MIXED PHRASES
    GlobalVoiceIntent.openTasks: [
      'daily tasks open cheyyi',
      'daily tasks open pannu',
      'daily tasks open maadi',
      'daily tasks kholo',
      'task list open cheyyi',
      'task list open pannu',
      'task list open maadi',
      'task list kholo',
    ],

    // 15. REMINDERS MIXED PHRASES
    GlobalVoiceIntent.openReminders: [
      'reminders open cheyyi',
      'reminders open pannu',
      'reminders open maadi',
      'reminders kholo',
      'medication reminders open cheyyi',
      'medication reminders open pannu',
      'medication reminders open maadi',
      'medication reminders kholo',
    ],

    // 16. NOTES MIXED PHRASES
    GlobalVoiceIntent.openNotes: [
      'notes open cheyyi',
      'notes open pannu',
      'notes open maadi',
      'notes kholo',
      'memory notes open cheyyi',
      'memory notes open pannu',
      'memory notes open maadi',
      'memory notes kholo',
    ],

    // 17. SPEECH ASSISTANCE MIXED PHRASES
    GlobalVoiceIntent.openSpeechAssistance: [
      'speech assistance open cheyyi',
      'speech assistance open pannu',
      'speech assistance open maadi',
      'speech assistance kholo',
      'voice assistant open cheyyi',
      'voice assistant open pannu',
      'voice assistant open maadi',
      'voice assistant kholo',
    ],

    // 18. CHANGE LANGUAGE MIXED PHRASES
    GlobalVoiceIntent.changeLanguage: [
      'language change cheyi',
      'language change pannu',
      'language change maadi',
      'language change karo',
      'language settings open cheyyi',
      'language settings open pannu',
      'language settings open maadi',
      'language settings kholo',
      'telugu language ki marchu',
      'tamil mozhi ku maathu',
      'kannada bhashe ge badalisi',
      'hindi me badlo',
      'english me change karo',
    ],

    // 19. HELP MIXED PHRASES
    GlobalVoiceIntent.help: [
      'voice commands list chupinchu',
      'voice commands list kaattu',
      'voice commands list thorisu',
      'voice commands list dikhao',
      'help screen open cheyyi',
      'help screen open pannu',
      'help screen open maadi',
      'help screen kholo',
    ],
  };
}
