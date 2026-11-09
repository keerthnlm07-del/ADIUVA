import 'package:flutter/foundation.dart';
import '../../domain/entities/voice_action.dart';
import '../voice_language_dataset/global_voice_intents.dart';
import '../voice_language_dataset/english_voice_phrases.dart';
import '../voice_language_dataset/telugu_voice_phrases.dart';
import '../voice_language_dataset/tamil_voice_phrases.dart';
import '../voice_language_dataset/kannada_voice_phrases.dart';
import '../voice_language_dataset/hindi_voice_phrases.dart';
import '../voice_language_dataset/mixed_language_phrases.dart';

/// Centralized, screen-aware registry for binding touch and voice actions
class VoiceActionRegistry {
  final Map<String, VoiceAction> _globalActions = {};
  final Map<String, Map<String, VoiceAction>> _screenActions = {};

  VoiceActionRegistry() {
    _registerDefaultGlobalActions();
    _registerMultilingualDataset();
  }

  void _registerDefaultGlobalActions() {
    // Built-in global fallback actions
    registerAction(const VoiceAction(
      id: 'open_sign_to_text',
      label: 'Sign Language to Text',
      screenContext: 'global',
      aliases: [
        'open sign language to text',
        'sign language to text',
        'open sign to text',
        'sign to text',
        'sign recognition'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'open_text_to_sign',
      label: 'Text to Sign Language',
      screenContext: 'global',
      aliases: [
        'open text to sign language',
        'text to sign language',
        'open text to sign',
        'text to sign',
        'sign demonstration'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'emergency_sos',
      label: 'Emergency SOS',
      screenContext: 'global',
      aliases: [
        'open sos',
        'open emergency',
        'emergency',
        'sos',
        'help me',
        'help help',
        'bachao',
        'aapathu',
        'kaappatru',
        'इमरजेंसी',
        'बचाओ',
        'आपत्कालीन',
        'ஆபத்து',
        'ஆபத்து உதவி',
        'ஆபத்து உதவி தேவை',
        'aapadhu',
        'ஆபத்து',
        'ఆపత్తు',
        'ఆపద',
        'ಆಪತ್ತು'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'go_home',
      label: 'Go Home',
      screenContext: 'global',
      aliases: [
        'home',
        'go home',
        'main menu',
        'open home',
        'home page',
        'dashboard',
        'take me home',
        'i want to go home',
        'please take me home',
        'can you take me home',
        'ghar chalo',
        'home pe chalo',
        'home chalo',
        'wapas jao',
        'होम पर जाओ',
        'घर चलो',
        'veettukku poganum',
        'வீட்டிற்கு போ',
        'வீட்டுக்கு செல்',
        'home-ku poganum',
        'home ku poganum',
        'illiki vellali',
        'ఇంటికి వెళ్లు',
        'home ki vellali',
        'manege hogbeku',
        'ಮನೆಗೆ ಹೋಗು',
        'home ge hogbeku'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'go_back',
      label: 'Go Back',
      screenContext: 'global',
      aliases: [
        'go back',
        'back',
        'return',
        'previous screen',
        'take me back',
        'piche jao',
        'wapas jao',
        'पीछे जाओ',
        'वापस जाओ',
        'pinnadi po',
        'பின்னால் போ',
        'திரும்பி போ',
        'venakki vellu',
        'వెనక్కి వెళ్లు',
        'hinde hogu',
        'ಹಿಂಗೆ ಹೋಗು'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'help',
      label: 'Help & Voice Commands',
      screenContext: 'global',
      aliases: [
        'help',
        'commands',
        'options',
        'what can i say',
        'help me',
        'madad',
        'sahaita',
        'मदद',
        'सहायता',
        'udhavi',
        'உதவி',
        'sahaayam',
        'సహాయం',
        'sahaya',
        'ಸಹಾಯ'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'stop_voice',
      label: 'Stop Voice',
      screenContext: 'global',
      aliases: [
        'stop',
        'cancel',
        'quiet',
        'hush',
        'roko',
        'rokna',
        'रोकें',
        'बंद करो',
        'kettathai niruthu',
        'கேட்பதை நிறுத்து',
        'vinadam aapu',
        'వినడం ఆపు',
        'keluvudannu nillisi',
        'ಕೇಳುವುದನ್ನು ನಿಲ್ಲಿಸು'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'open_location',
      label: 'Location',
      screenContext: 'global',
      aliases: [
        'location',
        'open location',
        'location screen',
        'location page',
        'where am i screen',
        'where am i',
        'what is my location',
        'tell me my location',
        'my current location',
        'current location',
        'show my location',
        'where am i right now',
        'please tell me where i am',
        'could you please tell me my current location',
        'can you tell me where i am',
        'show location',
        'tell my location',
        'where i am',
        'my location',
        'स्थान',
        'मेरी लोकेशन',
        'मेरा स्थान',
        'लोकेशन',
        'मैं कहाँ हूँ',
        'main kahan hoon',
        'meri location',
        'mera sthaan',
        'naan engae irukkiren',
        'நான் எங்கே இருக்கிறேன்',
        'naan engae irukken',
        'இடம்',
        'என் இருப்பிடம்',
        'என் இடம்',
        'இருப்பிடம்',
        'idaam',
        'idam',
        'en iruppidam',
        'nenu ekkada unnanu',
        'నేను ఎక్కడ ఉన్నాను',
        'నేను ఎక్కడ ఉన్నా',
        'స్థానం',
        'నా స్థానం',
        'నా లొకేషన్',
        'sthaanam',
        'naa sthaanam',
        'naa location',
        'naanu elliddene',
        'ನಾನು ಎಲ್ಲಿದ್ದೇನೆ',
        'ಸ್ಥಳ',
        'ನನ್ನ ಸ್ಥಳ',
        'ನನ್ನ ಲೊಕೇಶನ್',
        'sthala',
        'nanna sthala',
        'nanna location'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'open_visual_assistance',
      label: 'Visual Assistance',
      screenContext: 'global',
      aliases: [
        'open visual assistance',
        'visual assistance',
        'open visual',
        'visual mode',
        'vision assistance',
        'open vision assistance',
        'vision mode',
        'open vision mode',
        'open vision',
        'vision',
        'blind assistance',
        'open blind assistance',
        'blind mode',
        'open blind mode',
        'drishti sahaita',
        'drishti sahayata',
        'दृष्टि सहायता',
        'विजुअल असिस्टेंस',
        'விஷுவல் அசிஸ்டென்ஸ்',
        'பார்வை உதவி',
        'విజ్యువల్ అసిస్టెన్స్',
        'దృష్టి సహాయం',
        'ವಿಷುವಲ್ ಅಸಿಸ್ಟೆನ್ಸ್',
        'ದೃಷ್ಟಿ ನೆರವು'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'object_detection',
      label: 'Object Detection',
      screenContext: 'global',
      aliases: [
        'object detection',
        'open object detection',
        'detect objects',
        'identify object',
        'open object detector',
        'object detector',
        'detect object',
        'what is in front of me',
        'scan objects',
        'identify items',
        'recognize objects',
        'find objects around me',
        'object recognition',
        'open object recognition',
        'वस्तु पहचान',
        'பொருள் கண்டறிதல்',
        'వస్తు గుర్తింపు',
        'ವಸ್ತು ಗುರುತಿಸುವಿಕೆ'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'start_object_detection',
      label: 'Start Object Detection',
      screenContext: 'global',
      aliases: [
        'start object detection',
        'start detection',
        'resume object detection',
        'start object recognition',
        'begin object detection',
        'start detecting objects',
        'detect objects now'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'stop_object_detection',
      label: 'Stop Object Detection',
      screenContext: 'global',
      aliases: [
        'stop object detection',
        'stop detection',
        'pause object detection',
        'stop object recognition',
        'stop detecting objects',
        'pause detection'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'ocr',
      label: 'Read Text',
      screenContext: 'global',
      aliases: [
        'ocr',
        'read text',
        'open read text',
        'read words',
        'scan text',
        'text reader',
        'open text reader',
        'read document',
        'read book',
        'read sign',
        'read paper',
        'पाठ पढ़ें',
        'உரையைப் படியுங்கள்',
        'వచనాన్ని చదవండి',
        'ಪಠ್ಯವನ್ನು ಓದಿ'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'scene_description',
      label: 'Scene Description',
      screenContext: 'global',
      aliases: [
        'scene description',
        'open scene description',
        'describe scene',
        'describe the scene',
        'what is around me',
        'what do you see',
        'describe surroundings',
        'surroundings description',
        'दृश्य विवरण',
        'காட்சி விளக்கம்',
        'దృశ్య వివరణ',
        'ದೃಶ್ಯ ವಿವರಣೆ'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'open_sign_language',
      label: 'Sign Language',
      screenContext: 'global',
      aliases: [
        'open sign language',
        'sign language',
        'open sign language home',
        'sign language home',
        'sign home',
        'open isl',
        'isl',
        'सांकेतिक भाषा',
        'சைகை மொழி',
        'సైగ భాష',
        'ಸನ್ನೆ ಭಾಷೆ'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'open_translator',
      label: 'Translator',
      screenContext: 'global',
      aliases: [
        'open translator',
        'translator',
        'open translation',
        'translation',
        'translate',
        'open speech translator',
        'anuvadak',
        'anuvad',
        'अनुवादक',
        'மொழிபெயர்ப்பாளர்',
        'అనువాదకుడు',
        'ಅನುವಾದಕ'
      ],
    ));

    registerAction(const VoiceAction(
      id: 'repeat_speech',
      label: 'Repeat Speech',
      screenContext: 'global',
      aliases: [
        'repeat',
        'repeat that',
        'read again',
        'say again',
        'what did you say',
        'repeat speech',
        'फिर से बोलो',
        'மீண்டும் சொல்',
        'మళ్ళీ చెప్పు',
        'ಮತ್ತೆ ಹೇಳು'
      ],
    ));
  }

  /// Register an individual VoiceAction (merges aliases if action already registered)
  void registerAction(VoiceAction action) {
    final contextKey = action.screenContext.toLowerCase().trim();
    if (contextKey == 'global') {
      if (_globalActions.containsKey(action.id)) {
        final existing = _globalActions[action.id]!;
        final mergedSet = <String>{...existing.aliases, ...action.aliases};
        _globalActions[action.id] = VoiceAction(
          id: action.id,
          label: action.label.isNotEmpty ? action.label : existing.label,
          screenContext: action.screenContext,
          aliases: mergedSet.toList(),
          contextualAliases: existing.contextualAliases,
        );
      } else {
        _globalActions[action.id] = action;
      }
    } else {
      final screenMap = _screenActions.putIfAbsent(contextKey, () => {});
      if (screenMap.containsKey(action.id)) {
        final existing = screenMap[action.id]!;
        final mergedSet = <String>{...existing.aliases, ...action.aliases};
        screenMap[action.id] = VoiceAction(
          id: action.id,
          label: action.label.isNotEmpty ? action.label : existing.label,
          screenContext: action.screenContext,
          aliases: mergedSet.toList(),
          contextualAliases: existing.contextualAliases,
        );
      } else {
        screenMap[action.id] = action;
      }
    }
  }

  void _registerMultilingualDataset() {
    final intentMetadata = <String, Map<String, String>>{
      GlobalVoiceIntent.openLocation: {'label': 'Location', 'context': 'global'},
      GlobalVoiceIntent.goHome: {'label': 'Go Home', 'context': 'global'},
      GlobalVoiceIntent.goBack: {'label': 'Go Back', 'context': 'global'},
      GlobalVoiceIntent.emergencySos: {'label': 'Emergency SOS', 'context': 'global'},
      GlobalVoiceIntent.help: {'label': 'Help & Voice Commands', 'context': 'global'},
      GlobalVoiceIntent.openVisualAssistance: {'label': 'Visual Assistance', 'context': 'global'},
      GlobalVoiceIntent.objectDetection: {'label': 'Object Detection', 'context': 'global'},
      GlobalVoiceIntent.ocr: {'label': 'Read Text', 'context': 'global'},
      GlobalVoiceIntent.sceneDescription: {'label': 'Scene Description', 'context': 'global'},
      GlobalVoiceIntent.documentReader: {'label': 'Document Reader', 'context': 'global'},
      GlobalVoiceIntent.openHearingAssistance: {'label': 'Hearing Assistance', 'context': 'global'},
      GlobalVoiceIntent.openSignLanguage: {'label': 'Sign Language', 'context': 'global'},
      GlobalVoiceIntent.openTranslator: {'label': 'Translator', 'context': 'global'},
      GlobalVoiceIntent.openCognitiveAssistance: {'label': 'Cognitive Assistance', 'context': 'global'},
      GlobalVoiceIntent.openTasks: {'label': 'Daily Tasks', 'context': 'global'},
      GlobalVoiceIntent.openReminders: {'label': 'Reminders', 'context': 'global'},
      GlobalVoiceIntent.openNotes: {'label': 'Notes & Memory', 'context': 'global'},
      GlobalVoiceIntent.openPhysicalAssistance: {'label': 'Physical Assistance', 'context': 'global'},
      GlobalVoiceIntent.openSpeechAssistance: {'label': 'Speech Assistant', 'context': 'global'},
      GlobalVoiceIntent.openNormalUser: {'label': 'Normal User', 'context': 'global'},
      GlobalVoiceIntent.changeLanguage: {'label': 'Change Language', 'context': 'global'},
    };

    for (final intent in GlobalVoiceIntent.allIntents) {
      final intentId = intent.id;
      final Set<String> allAliases = {};

      // English
      final english = EnglishVoicePhrases.phrasesByIntent[intentId];
      if (english != null) allAliases.addAll(english);

      // Telugu
      final telugu = TeluguVoicePhrases.phrasesByIntent[intentId];
      if (telugu != null) {
        for (final pair in telugu) {
          allAliases.add(pair.native);
          allAliases.add(pair.transliteration);
        }
      }

      // Tamil
      final tamil = TamilVoicePhrases.phrasesByIntent[intentId];
      if (tamil != null) {
        for (final pair in tamil) {
          allAliases.add(pair.native);
          allAliases.add(pair.transliteration);
        }
      }

      // Kannada
      final kannada = KannadaVoicePhrases.phrasesByIntent[intentId];
      if (kannada != null) {
        for (final pair in kannada) {
          allAliases.add(pair.native);
          allAliases.add(pair.transliteration);
        }
      }

      // Hindi
      final hindi = HindiVoicePhrases.phrasesByIntent[intentId];
      if (hindi != null) {
        for (final pair in hindi) {
          allAliases.add(pair.native);
          allAliases.add(pair.transliteration);
        }
      }

      // Mixed
      final mixed = MixedLanguagePhrases.phrasesByIntent[intentId];
      if (mixed != null) allAliases.addAll(mixed);

      final meta = intentMetadata[intentId] ?? {'label': intent.englishLabel, 'context': 'global'};

      registerAction(VoiceAction(
        id: intentId,
        label: meta['label']!,
        screenContext: meta['context']!,
        aliases: allAliases.toList(),
      ));

      if (intentId == GlobalVoiceIntent.openTasks) {
        registerAction(VoiceAction(
          id: 'open_daily_tasks',
          label: meta['label']!,
          screenContext: meta['context']!,
          aliases: allAliases.toList(),
        ));
      }
    }
  }

  /// Register a batch of VoiceActions
  void registerActions(List<VoiceAction> actions) {
    for (final action in actions) {
      registerAction(action);
    }
  }

  /// Clear registered actions for a specific screen context
  void unregisterScreenActions(String screenContext) {
    _screenActions.remove(screenContext.toLowerCase().trim());
  }

  /// Resolve a voice transcript against current screen context and global actions
  VoiceActionMatch? resolveAction({
    required String rawTranscript,
    required String currentScreenContext,
  }) {
    final String cleanTranscript = _normalizeTranscript(rawTranscript);
    final String screenKey = currentScreenContext.toLowerCase().trim();

    debugPrint('[VOICE_COMMAND] screen=$screenKey transcript="$rawTranscript" matchedAction=TRYING_RESOLUTION');

    if (cleanTranscript.isEmpty) {
      debugPrint('[VOICE_COMMAND] screen=$screenKey transcript="" matchedAction=NONE');
      debugPrint('[VOICE_ACTION] actionId=NONE status=NO_MATCH');
      return null;
    }

    // 1. Check screen-specific actions first (Highest Priority)
    final screenMap = _getCombinedScreenActions(screenKey);
    for (final action in screenMap.values) {
      final matchedAlias = _findMatchingAlias(cleanTranscript, action);
      if (matchedAlias != null) {
        debugPrint('[VOICE_COMMAND] screen=$screenKey transcript="$rawTranscript" matchedAction=${action.id}');
        debugPrint('[VOICE_ACTION] actionId=${action.id} status=EXECUTED');
        return VoiceActionMatch(
          action: action,
          transcript: rawTranscript,
          matchedAlias: matchedAlias,
        );
      }
    }

    // 2. Check global actions if screen-specific did not match
    for (final action in _globalActions.values) {
      final matchedAlias = _findMatchingAlias(cleanTranscript, action);
      if (matchedAlias != null) {
        debugPrint('[VOICE_COMMAND] screen=$screenKey transcript="$rawTranscript" matchedAction=${action.id}');
        debugPrint('[VOICE_ACTION] actionId=${action.id} status=EXECUTED');
        return VoiceActionMatch(
          action: action,
          transcript: rawTranscript,
          matchedAlias: matchedAlias,
        );
      }
    }

    debugPrint('[VOICE_COMMAND] screen=$screenKey transcript="$rawTranscript" matchedAction=NONE');
    debugPrint('[VOICE_ACTION] actionId=NONE status=NO_MATCH');
    return null;
  }

  /// Returns combined actions for screen key including aliases (e.g. 'vision' & 'visual_assistance')
  Map<String, VoiceAction> _getCombinedScreenActions(String screenKey) {
    final Map<String, VoiceAction> combined = {};

    // Direct match
    if (_screenActions.containsKey(screenKey)) {
      combined.addAll(_screenActions[screenKey]!);
    }

    // Context alias mapping
    if (screenKey.contains('vision') || screenKey.contains('visual') || screenKey.contains('ocr') || screenKey.contains('readtext')) {
      for (final key in _screenActions.keys) {
        if (key.contains('vision') || key.contains('visual') || key.contains('ocr') || key.contains('readtext')) {
          combined.addAll(_screenActions[key]!);
        }
      }
    } else if (screenKey.contains('home') || screenKey.contains('dashboard')) {
      for (final key in _screenActions.keys) {
        if (key.contains('home') || key.contains('dashboard')) {
          combined.addAll(_screenActions[key]!);
        }
      }
    }

    return combined;
  }

  String? _findMatchingAlias(String cleanInput, VoiceAction action) {
    // 1. Check exact primary aliases (highest priority)
    for (final alias in action.aliases) {
      final cleanAlias = _normalizeTranscript(alias);
      if (cleanInput == cleanAlias) {
        return alias;
      }
    }

    // 2. Check multi-word phrase primary aliases (must contain space and be length >= 4)
    for (final alias in action.aliases) {
      final cleanAlias = _normalizeTranscript(alias);
      if (cleanAlias.length >= 4 && cleanAlias.contains(' ') && cleanInput.contains(cleanAlias)) {
        return alias;
      }
    }

    // 3. Check safe single-word primary aliases (length >= 4, whole-word boundary match e.g. "location", "idam")
    for (final alias in action.aliases) {
      final cleanAlias = _normalizeTranscript(alias);
      if (cleanAlias.length >= 4 && !cleanAlias.contains(' ')) {
        if (cleanAlias == 'home' || cleanAlias == 'back' || cleanAlias == 'help' || cleanAlias == 'stop') continue;
        if (RegExp(r'\b' + RegExp.escape(cleanAlias) + r'\b').hasMatch(cleanInput)) {
          return alias;
        }
      }
    }

    // 4. Safe Phonetic Transliteration Variant Match for multi-word phrases
    final phoneticInput = _normalizePhoneticTransliteration(cleanInput);
    if (phoneticInput.isNotEmpty) {
      for (final alias in action.aliases) {
        final cleanAlias = _normalizeTranscript(alias);
        if (cleanAlias.contains(' ') || cleanAlias.length >= 5) {
          final phoneticAlias = _normalizePhoneticTransliteration(alias);
          if (phoneticAlias.isNotEmpty) {
            if (phoneticInput == phoneticAlias ||
                (phoneticAlias.length >= 7 &&
                    RegExp(r'\b' + RegExp.escape(phoneticAlias) + r'\b').hasMatch(phoneticInput))) {
              return alias;
            }
          }
        }
      }
    }

    // 5. Check contextual aliases
    for (final alias in action.contextualAliases) {
      final cleanAlias = _normalizeTranscript(alias);
      if (cleanInput == cleanAlias || (cleanAlias.length >= 5 && cleanAlias.contains(' ') && cleanInput.contains(cleanAlias))) {
        return alias;
      }
    }

    return null;
  }

  String _normalizeTranscript(String input) {
    return input
        .replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '')
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizePhoneticTransliteration(String input) {
    String text = _normalizeTranscript(input);
    if (text.isEmpty) return '';

    // Standardize vowels
    text = text
        .replaceAll('aa', 'a')
        .replaceAll('ee', 'i')
        .replaceAll('oo', 'u')
        .replaceAll('ou', 'u')
        .replaceAll('ei', 'i')
        .replaceAll('ai', 'e');

    // Standardize consonants
    text = text
        .replaceAll('dd', 'd')
        .replaceAll('ll', 'l')
        .replaceAll('tt', 't')
        .replaceAll('kk', 'k')
        .replaceAll('pp', 'p')
        .replaceAll('nn', 'n')
        .replaceAll('mm', 'm')
        .replaceAll('ss', 's')
        .replaceAll('rr', 'r')
        .replaceAll('ch', 'c')
        .replaceAll('sh', 's')
        .replaceAll('th', 't');

    // Standardize common phonetic endings for regional transliterations
    text = text
        .replaceAll(RegExp(r'iddini$'), 'idene')
        .replaceAll(RegExp(r'iddene$'), 'idene')
        .replaceAll(RegExp(r'iddini\b'), 'idene')
        .replaceAll(RegExp(r'iddene\b'), 'idene')
        .replaceAll(RegExp(r'hu$'), 'hoon')
        .replaceAll(RegExp(r'hu\b'), 'hoon')
        .replaceAll(RegExp(r'irukken$'), 'irukkiren')
        .replaceAll(RegExp(r'irukken\b'), 'irukkiren')
        .replaceAll(RegExp(r'unna$'), 'unnanu')
        .replaceAll(RegExp(r'unna\b'), 'unnanu');

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
