/// Canonical Voice Intent IDs and Categories for ADIUVA Global Multilingual Voice Control
class GlobalVoiceIntent {
  final String id;
  final String category;
  final String englishLabel;
  final String defaultTtsResponse;

  const GlobalVoiceIntent({
    required this.id,
    required this.category,
    required this.englishLabel,
    required this.defaultTtsResponse,
  });

  // Canonical Intent IDs (matching existing project conventions)
  static const String openLocation = 'open_location';
  static const String goHome = 'go_home';
  static const String goBack = 'go_back';
  static const String emergencySos = 'emergency_sos';
  static const String help = 'help';
  static const String openVisualAssistance = 'open_visual_assistance';
  static const String objectDetection = 'object_detection';
  static const String ocr = 'ocr';
  static const String sceneDescription = 'scene_description';
  static const String documentReader = 'document_reader';
  static const String openHearingAssistance = 'open_hearing_assistance';
  static const String openSignLanguage = 'open_sign_language';
  static const String openTranslator = 'open_translator';
  static const String openCognitiveAssistance = 'open_cognitive_assistance';
  static const String openTasks = 'open_tasks';
  static const String openReminders = 'open_reminders';
  static const String openNotes = 'open_notes';
  static const String openPhysicalAssistance = 'open_physical_assistance';
  static const String openSpeechAssistance = 'open_speech_assistance';
  static const String openNormalUser = 'open_normal_user';
  static const String changeLanguage = 'change_language';

  static const List<GlobalVoiceIntent> allIntents = [
    GlobalVoiceIntent(
      id: openLocation,
      category: 'location',
      englishLabel: 'Location & Where Am I',
      defaultTtsResponse: 'Fetching your current location.',
    ),
    GlobalVoiceIntent(
      id: goHome,
      category: 'navigation',
      englishLabel: 'Go Home',
      defaultTtsResponse: 'Returning to Home Dashboard.',
    ),
    GlobalVoiceIntent(
      id: goBack,
      category: 'navigation',
      englishLabel: 'Go Back',
      defaultTtsResponse: 'Going back.',
    ),
    GlobalVoiceIntent(
      id: emergencySos,
      category: 'emergency',
      englishLabel: 'Emergency SOS',
      defaultTtsResponse: 'Opening Emergency SOS.',
    ),
    GlobalVoiceIntent(
      id: help,
      category: 'system',
      englishLabel: 'Help & Voice Commands',
      defaultTtsResponse: 'Available voice commands.',
    ),
    GlobalVoiceIntent(
      id: openVisualAssistance,
      category: 'visual',
      englishLabel: 'Visual Assistance',
      defaultTtsResponse: 'Opening Visual Assistance.',
    ),
    GlobalVoiceIntent(
      id: objectDetection,
      category: 'visual',
      englishLabel: 'Object Detection',
      defaultTtsResponse: 'Opening Object Detection.',
    ),
    GlobalVoiceIntent(
      id: ocr,
      category: 'visual',
      englishLabel: 'OCR Text Reader',
      defaultTtsResponse: 'Opening OCR Text Reader.',
    ),
    GlobalVoiceIntent(
      id: sceneDescription,
      category: 'visual',
      englishLabel: 'Scene Description',
      defaultTtsResponse: 'Opening Scene Description.',
    ),
    GlobalVoiceIntent(
      id: documentReader,
      category: 'visual',
      englishLabel: 'Document & Storybook Reader',
      defaultTtsResponse: 'Opening Document Reader.',
    ),
    GlobalVoiceIntent(
      id: openHearingAssistance,
      category: 'hearing',
      englishLabel: 'Hearing Assistance',
      defaultTtsResponse: 'Opening Hearing Helper.',
    ),
    GlobalVoiceIntent(
      id: openSignLanguage,
      category: 'hearing',
      englishLabel: 'Sign Language Translator',
      defaultTtsResponse: 'Opening Sign Language Translator.',
    ),
    GlobalVoiceIntent(
      id: openTranslator,
      category: 'translator',
      englishLabel: 'Translator',
      defaultTtsResponse: 'Opening Translator.',
    ),
    GlobalVoiceIntent(
      id: openCognitiveAssistance,
      category: 'cognitive',
      englishLabel: 'Cognitive Assistance',
      defaultTtsResponse: 'Opening Cognitive Assistance.',
    ),
    GlobalVoiceIntent(
      id: openTasks,
      category: 'cognitive',
      englishLabel: 'Daily Tasks',
      defaultTtsResponse: 'Opening Daily Tasks.',
    ),
    GlobalVoiceIntent(
      id: openReminders,
      category: 'cognitive',
      englishLabel: 'Reminders & Medication',
      defaultTtsResponse: 'Opening Reminders and Medication.',
    ),
    GlobalVoiceIntent(
      id: openNotes,
      category: 'cognitive',
      englishLabel: 'Notes & Memory',
      defaultTtsResponse: 'Opening Notes and Memory.',
    ),
    GlobalVoiceIntent(
      id: openPhysicalAssistance,
      category: 'physical',
      englishLabel: 'Physical Assistance',
      defaultTtsResponse: 'Opening Physical Assistance.',
    ),
    GlobalVoiceIntent(
      id: openSpeechAssistance,
      category: 'speech',
      englishLabel: 'Speech AI Assistant',
      defaultTtsResponse: 'Opening Speech AI Assistant.',
    ),
    GlobalVoiceIntent(
      id: openNormalUser,
      category: 'navigation',
      englishLabel: 'Normal User Suite',
      defaultTtsResponse: 'Opening Normal User Suite.',
    ),
    GlobalVoiceIntent(
      id: changeLanguage,
      category: 'system',
      englishLabel: 'Change Language',
      defaultTtsResponse: 'Changing voice language.',
    ),
  ];
}
