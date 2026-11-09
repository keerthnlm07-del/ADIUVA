import '../../features/speech_assistance/data/voice_language_dataset/global_voice_intents.dart';
import '../../features/speech_assistance/data/voice_language_dataset/telugu_voice_phrases.dart';
import '../../features/speech_assistance/data/voice_language_dataset/tamil_voice_phrases.dart';
import '../../features/speech_assistance/data/voice_language_dataset/kannada_voice_phrases.dart';
import '../../features/speech_assistance/data/voice_language_dataset/hindi_voice_phrases.dart';

/// Multilingual Phrase Model for ADIUVA Conversational Voice System
class MultilingualPhrase {
  final String intent;
  final String category;
  final String englishText;
  final Map<String, String> nativeTextMap;
  final Map<String, String> transliterationMap;
  final Map<String, List<String>> aliasesMap;

  const MultilingualPhrase({
    required this.intent,
    required this.category,
    required this.englishText,
    required this.nativeTextMap,
    required this.transliterationMap,
    required this.aliasesMap,
  });

  /// Get dual-representation display string for UI (Native TOP, Transliteration UNDERNEATH)
  String getDisplayString(String? localeId) {
    final cleanLang = VoiceResponseLocalizer.normalizeLocale(localeId).split('-').first;
    if (cleanLang == 'en') return englishText;
    final native = nativeTextMap[cleanLang];
    final trans = transliterationMap[cleanLang];
    if (native != null && trans != null && trans.trim().isNotEmpty) {
      return '$native\n$trans';
    }
    return native ?? englishText;
  }

  /// Get speakable string for TTS engine (Native script for natural regional TTS)
  String getTtsString(String? localeId) {
    final cleanLang = VoiceResponseLocalizer.normalizeLocale(localeId).split('-').first;
    if (cleanLang == 'en') return englishText;
    return nativeTextMap[cleanLang] ?? englishText;
  }
}

/// Centralized Localized System Voice Response Provider & Language Parser for ADIUVA
class VoiceResponseLocalizer {
  static String normalizeLocale(String? localeId) {
    if (localeId == null || localeId.isEmpty) return 'en-IN';
    final clean = localeId.toLowerCase().replaceAll('_', '-');
    if (clean.startsWith('hi')) return 'hi-IN';
    if (clean.startsWith('kn')) return 'kn-IN';
    if (clean.startsWith('te')) return 'te-IN';
    if (clean.startsWith('ta')) return 'ta-IN';
    return 'en-IN';
  }

  /// Format recognized user speech for UI display:
  /// - English: Single line English text
  /// - Regional / Transliteration: Native script (Line 1) + Transliteration (Line 2) if phrase pair matched
  static String formatRecognizedUserSpeech(String transcript, String? localeId) {
    final cleanLang = normalizeLocale(localeId).split('-').first;
    if (cleanLang == 'en') return transcript;

    final clean = transcript
        .replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '')
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return transcript;

    final phoneticClean = _normalizePhoneticTransliteration(clean);

    for (final intent in GlobalVoiceIntent.allIntents) {
      final tePhrases = TeluguVoicePhrases.phrasesByIntent[intent.id];
      if (tePhrases != null) {
        for (final pair in tePhrases) {
          final cleanNative = pair.native.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
          final cleanTrans = pair.transliteration.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
          final phoneticTrans = _normalizePhoneticTransliteration(cleanTrans);
          if (clean == cleanNative || clean == cleanTrans || (phoneticClean.isNotEmpty && phoneticClean == phoneticTrans)) {
            return '${pair.native}\n${pair.transliteration}';
          }
        }
      }

      final taPhrases = TamilVoicePhrases.phrasesByIntent[intent.id];
      if (taPhrases != null) {
        for (final pair in taPhrases) {
          final cleanNative = pair.native.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
          final cleanTrans = pair.transliteration.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
          final phoneticTrans = _normalizePhoneticTransliteration(cleanTrans);
          if (clean == cleanNative || clean == cleanTrans || (phoneticClean.isNotEmpty && phoneticClean == phoneticTrans)) {
            return '${pair.native}\n${pair.transliteration}';
          }
        }
      }

      final knPhrases = KannadaVoicePhrases.phrasesByIntent[intent.id];
      if (knPhrases != null) {
        for (final pair in knPhrases) {
          final cleanNative = pair.native.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
          final cleanTrans = pair.transliteration.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
          final phoneticTrans = _normalizePhoneticTransliteration(cleanTrans);
          if (clean == cleanNative || clean == cleanTrans || (phoneticClean.isNotEmpty && phoneticClean == phoneticTrans)) {
            return '${pair.native}\n${pair.transliteration}';
          }
        }
      }

      final hiPhrases = HindiVoicePhrases.phrasesByIntent[intent.id];
      if (hiPhrases != null) {
        for (final pair in hiPhrases) {
          final cleanNative = pair.native.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
          final cleanTrans = pair.transliteration.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
          final phoneticTrans = _normalizePhoneticTransliteration(cleanTrans);
          if (clean == cleanNative || clean == cleanTrans || (phoneticClean.isNotEmpty && phoneticClean == phoneticTrans)) {
            return '${pair.native}\n${pair.transliteration}';
          }
        }
      }
    }

    return transcript;
  }

  static String _normalizePhoneticTransliteration(String input) {
    String text = input.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
    if (text.isEmpty) return '';

    text = text
        .replaceAll('aa', 'a')
        .replaceAll('ee', 'i')
        .replaceAll('oo', 'u')
        .replaceAll('ou', 'u')
        .replaceAll('ei', 'i')
        .replaceAll('ai', 'e')
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
        .replaceAll('th', 't')
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

  static String languageAlreadyActive(String? localeId) {
    switch (normalizeLocale(localeId)) {
      case 'hi-IN':
        return 'भाषा पहले से ही हिंदी है।\nBhasha pehle se hi Hindi hai.';
      case 'kn-IN':
        return 'ಭಾಷೆ ಈಗಾಗಲೇ ಕನ್ನಡವಾಗಿದೆ.\nBhashe eagaagale Kannadavaagide.';
      case 'te-IN':
        return 'భాష ఇప్పటికే తెలుగులో ఉంది.\nBhasha ippatike Telugulo undhi.';
      case 'ta-IN':
        return 'மொழி ஏற்கனவே தமிழில் உள்ளது.\nMozhi earkkanave Tamilil ulladhu.';
      default:
        return 'Language is already English.';
    }
  }

  static String welcomeMessage(String? localeId) {
    switch (normalizeLocale(localeId)) {
      case 'hi-IN':
        return 'ADIUVA में आपका स्वागत है। जारी रखने के लिए कृपया साइन इन या साइन अप करें।\nADIUVA me aapka swagat hai. Jaari rakhne ke liye kripya sign in ya sign up karein.';
      case 'kn-IN':
        return 'ADIUVA ಗೆ ಸ್ವಾಗತ. ಮುಂದುವರೆಯಲು ದಯವಿಟ್ಟು ಸೈನ್ ಇನ್ ಅಥವಾ ಸೈನ್ ಅಪ್ ಮಾಡಿ.\nADIUVA ge swaagatha. Mundhuvareyalu dayavittu sign in athava sign up maadi.';
      case 'te-IN':
        return 'ADIUVA కి స్వాగతం. కొనసాగడానికి దయచేసి సైన్ ఇన్ లేదా సైన్ అప్ చేయండి.\nADIUVA ki swaagatham. Konasaagadaniki dayachesi sign in leda sign up cheyandi.';
      case 'ta-IN':
        return 'ADIUVA விற்கு வரவேற்கிறோம். தொடர தயவுசெய்து உள்நுழையவும் அல்லது பதிவு செய்யவும்.\nADIUVA virku varaverkirom. Thodara thayavuseydhu ulnulaiyavum illaiyadhu padhivu seyyavum.';
      default:
        return 'Welcome to ADIUVA. Please sign in or sign up to continue.';
    }
  }

  static String returningWelcome(String? localeId, String? preferredName) {
    final name = (preferredName != null && preferredName.trim().isNotEmpty)
        ? preferredName.trim()
        : null;
    switch (normalizeLocale(localeId)) {
      case 'hi-IN':
        return name != null
            ? 'वापसी पर स्वागत है, $name। वॉइस कंट्रोल सक्रिय है।\nWaapsi par swagat hai, $name. Voice control sakriya hai.'
            : 'वापसी पर स्वागत है। वॉइस कंट्रोल सक्रिय है।\nWaapsi par swagat hai. Voice control sakriya hai.';
      case 'kn-IN':
        return name != null
            ? 'ಮರಳಿ ಬಂದಿದ್ದಕ್ಕೆ ಸ್ವಾಗತ, $name. ವಾಯ್ಸ್ ಕಂಟ್ರೋಲ್ ಸಕ್ರಿಯವಾಗಿದೆ.\nMarali bandhiddakke swaagatha, $name. Voice control sakriyavaagide.'
            : 'ಮರಳಿ ಬಂದಿದ್ದಕ್ಕೆ ಸ್ವಾಗತ. ವಾಯ್ಸ್ ಕಂಟ್ರೋಲ್ ಸಕ್ರಿಯವಾಗಿದೆ.\nMarali bandhiddakke swaagatha. Voice control sakriyavaagide.';
      case 'te-IN':
        return name != null
            ? 'తిరిగి స్వాగతం, $name. వాయిస్ కంట్రోల్ యాక్టివ్‌గా ఉంది.\nThirigi swaagatham, $name. Voice control active gaa undhi.'
            : 'తిరిగి స్వాగతం. వాయిస్ కంట్రోల్ యాక్టివ్‌గా ఉంది.\nThirigi swaagatham. Voice control active gaa undhi.';
      case 'ta-IN':
        return name != null
            ? 'மீண்டும் வருக, $name. குரல் கட்டுப்பாடு செயல்பாட்டில் உள்ளது.\nMeendum varuga, $name. Kural kattuppaadu seyalpaattil ulladhu.'
            : 'மீண்டும் வருக. குரல் கட்டுப்பாடு செயல்பாட்டில் உள்ளது.\nMeendum varuga. Kural kattuppaadu seyalpaattil ulladhu.';
      default:
        return name != null
            ? 'Welcome back, $name. Voice Control is active.'
            : 'Welcome back. Voice Control is active.';
    }
  }

  static String languageChangedConfirmation(String? localeId) {
    switch (normalizeLocale(localeId)) {
      case 'hi-IN':
        return 'भाषा हिंदी में बदल दी गई है।\nBhaasha Hindi mein badal di gayi hai.';
      case 'kn-IN':
        return 'ಭಾಷೆಯನ್ನು ಕನ್ನಡಕ್ಕೆ ಬದಲಾಯಿಸಲಾಗಿದೆ.\nBhaasheyannu Kannadakke badalaayisalaagide.';
      case 'te-IN':
        return 'భాషను తెలుగుకు మార్చాను.\nBhaashanu Teluguku maarchaanu.';
      case 'ta-IN':
        return 'மொழியை தமிழுக்கு மாற்றியுள்ளேன்.\nMozhiyai Tamilukku maatriyullen.';
      default:
        return 'Language changed to English.';
    }
  }

  static String formatLocationResponse(String? localeId, String address) {
    if (address.trim().isEmpty) {
      switch (normalizeLocale(localeId)) {
        case 'hi-IN':
          return 'लोकेशन की जानकारी उपलब्ध नहीं है।\nLocation ki jaankari uplabdh nahi hai.';
        case 'kn-IN':
          return 'ಸ್ಥಳದ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ.\nSthalada maahiti labhyavilla.';
        case 'te-IN':
          return 'లొకేషన్ సమాచారం అందుబాటులో లేదు.\nLocation samaacharam andhubaatulo ledhu.';
        case 'ta-IN':
          return 'இருப்பிட தகவல் கிடைக்கவில்லை.\nIruppidha thagaval kidakkavillai.';
        default:
          return 'Location information is currently unavailable.';
      }
    }

    switch (normalizeLocale(localeId)) {
      case 'hi-IN':
        return 'आपका वर्तमान स्थान $address है।\nAapka vartamaan sthaan $address hai.';
      case 'kn-IN':
        return 'ನಿಮ್ಮ ಪ್ರಸ್ತುತ ಸ್ಥಳ $address.\nNimma prastuta sthala $address.';
      case 'te-IN':
        return 'మీ ప్రస్తుత స్థానం $address.\nMee prastuta sthaanam $address.';
      case 'ta-IN':
        return 'உங்கள் தற்போதைய இருப்பிடம் $address.\nUngal tharpoathaiya iruppidam $address.';
      default:
        return 'Your current location is $address.';
    }
  }

  static String silenceWarning(String? localeId) {
    return '';
  }

  static String unrecognizedSubtleHint(String? localeId) {
    switch (normalizeLocale(localeId)) {
      case 'hi-IN':
        return 'उपलब्ध कमांड के लिए आप हेल्प बोल सकते हैं।\nUpalabdh command ke liye aap Help bol sakte hain.';
      case 'kn-IN':
        return 'ಲಭ್ಯವಿರುವ ಆಜ್ಞೆಗಳಿಗಾಗಿ ನೀವು Help ಎಂದು ಹೇಳಬಹುದು.\nLabhyaviruva aagnegaligaagi neevu Help endhu helabahudu.';
      case 'te-IN':
        return 'అందుబాటులో ఉన్న కమాండ్ల కోసం మీరు హెల్ప్ అని చెప్పవచ్చు.\nAndhubaatulo unna commandla kosam meeru Help ani cheppavacchu.';
      case 'ta-IN':
        return 'கிடைக்கும் கட்டளைகளுக்கு நீங்கள் Help என்று சொல்லலாம்.\nKidakkum kattalaigalukku neengal Help endru sollaalaam.';
      default:
        return 'You can say Help for available commands.';
    }
  }

  static String helpMessage(String? localeId, [String? contextName]) {
    switch (normalizeLocale(localeId)) {
      case 'hi-IN':
        return 'आप साइन इन, भाषा बदलें, विजुअल असिस्टेंस, हियरिंग असिस्टेंस, कॉग्निटिव असिस्टेंस, फिजिकल असिस्टेंस या गो होम बोल सकते हैं।\nAap Sign In, Change Language, Visual Assistance, Hearing Assistance, Cognitive Assistance, Physical Assistance ya Go Home bol sakte hain.';
      case 'kn-IN':
        return 'ನೀವು ಸೈನ್ ಇನ್, ಭಾಷೆ ಬದಲಾಯಿಸಿ, ದೃಷ್ಟಿ ನೆರವು, ಶ್ರವಣ ನೆರವು, ಕಾಗ್ನಿಟಿವ್ ನೆರವು, ದೈಹಿಕ ನೆರವು ಅಥವಾ ಗೋ ಹೋಮ್ ಎಂದು ಹೇಳಬಹುದು.\nNeevu Sign In, Change Language, Visual Assistance, Hearing Assistance, Cognitive Assistance, Physical Assistance athava Go Home endhu helabahudu.';
      case 'te-IN':
        return 'మీరు సైన్ ఇన్, భాష మార్చండి, విజ్యువల్ అసిస్టెన్స్, హియరింగ్ అసిస్టెన్స్, కాగ్నిటివ్ అసిస్టెన్స్, ఫిజికల్ అసిస్టెన్స్ లేదా గో హోమ్ అని చెప్పవచ్చు.\nMeeru Sign In, Change Language, Visual Assistance, Hearing Assistance, Cognitive Assistance, Physical Assistance leda Go Home ani cheppavacchu.';
      case 'ta-IN':
        return 'நீங்கள் சைன் இன், மொழி மாற்று, பார்வை உதவி, செவிப்புலன் உதவி, அறிவாற்றல் உதவி, உடல் உதவி அல்லது கோ ஹோம் என்று சொல்லலாம்.\nNeengal Sign In, Change Language, Visual Assistance, Hearing Assistance, Cognitive Assistance, Physical Assistance alladhu Go Home endru sollaalaam.';
      default:
        return 'You can say Sign In, Sign Up, Change Language, Open Visual Assistance, Open Hearing Assistance, Open Cognitive Assistance, Open Physical Assistance, Open Normal User, or Go Home.';
    }
  }

  static String permissionPrompt(String permissionType, String? localeId) {
    final loc = normalizeLocale(localeId);
    switch (permissionType) {
      case 'microphone':
        return _tr(loc,
            'Microphone access is required for voice control. Please allow microphone access.',
            'वॉयस कंट्रोल के लिए माइक्रोफ़ोन की अनुमति आवश्यक है।\nVoice control ke liye microphone ki anumati aavashyak hai.',
            'ಧ್ವನಿ ನಿಯಂತ್ರಣಕ್ಕೆ ಮೈಕ್ರೋಫೋನ್ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ.\nDhvani niyantranakke microphone anumati agatyavide.',
            'వాయిస్ కంట్రోల్ కోసం మైక్రోఫోన్ అనుమతి అవసరం.\nVoice control kosam microphone anumati avasaram.',
            'குரல் கட்டுப்பாட்டுக்கு மைக்ரோஃபோன் அனுமதி தேவை.\nKural kattuppaattukku microphone anumadhi thevai.');
      case 'camera':
        return _tr(loc,
            'Camera access is required for visual assistance and sign language.',
            'दृष्टि सहायता के लिए कैमरा अनुमति आवश्यक है।\nDrishti sahaita ke liye camera anumati aavashyak hai.',
            'ದೃಷ್ಟಿ ನೆರವಿಗೆ ಕ್ಯಾಮೆರಾ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ.\nDrushti neravige camera anumati agatyavide.',
            'దృష్టి సహాయం కోసం కెమెరా అనుమతి అవసరం.\nDrushti sahaayam kosam camera anumati avasaram.',
            'பார்வை உதவிக்கு கேமரா அனுமதி தேவை.\nPaarvai udhavikku camera anumadhi thevai.');
      case 'location':
        return _tr(loc,
            'Location access is required for navigation and emergency assistance.',
            'लोकेशन अनुमति आवश्यक है।\nLocation anumati aavashyak hai.',
            'ಸ್ಥಳದ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ.\nSthalada anumati agatyavide.',
            'లొకేషన్ అనుమతి అవసరం.\nLocation anumati avasaram.',
            'இருப்பிட அனுமதி தேவை.\nIruppidha anumadhi thevai.');
      default:
        return _tr(loc, 'Permission access is required.', 'अनुमति आवश्यक है।', 'ಅನುಮತಿ ಅಗತ್ಯವಿದೆ.', 'అనుమతి అవసరం.', 'அனுமதி தேவை.');
    }
  }

  static String permissionDenied(String permissionType, String? localeId) {
    final loc = normalizeLocale(localeId);
    return _tr(
      loc,
      '$permissionType access is disabled. You can enable it later in Android Settings.',
      '$permissionType अनुमति बंद है।\n$permissionType anumati band hai.',
      '$permissionType ಅನುಮತಿ ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ.\n$permissionType anumati nishkriyagolisalaagide.',
      '$permissionType అనుమతి నిలిపివేయబడింది.\n$permissionType anumati nilapiveyabadindi.',
      '$permissionType அனுமதி முடக்கப்பட்டது.\n$permissionType anumadhi mudakkappattadhu.',
    );
  }

  static String modeSelected(String modeName, String? localeId) {
    final loc = normalizeLocale(localeId);
    return _tr(
      loc,
      '$modeName selected.',
      '$modeName चुन लिया गया है।\n$modeName chun liya gaya hai.',
      '$modeName ಆಯ್ಕೆಮಾಡಲಾಗಿದೆ.\n$modeName aaykemaadalaagide.',
      '$modeName ఎంచుకోబడింది.\n$modeName enchukobadindi.',
      '$modeName தேர்ந்தெடுக்கப்பட்டது.\n$modeName theerndhedukkappattadhu.',
    );
  }

  static String openingRoute(String routeKey, String? localeId) {
    final loc = normalizeLocale(localeId);
    switch (routeKey) {
      case 'login':
        return _tr(loc, 'Opening Sign In screen.', 'Sign In स्क्रीन खोल दिया गया है.\nSign In screen khol diya gaya hai.', 'Sign In ಪುಟ ತೆರೆಯಲಾಗಿದೆ.\nSign In puta tereyalaagide.', 'Sign In స్క్రీన్ తెరవబడింది.\nSign In screen teravabadindi.', 'Sign In திரை திறக்கப்பட்டது.\nSign In thirai thirakkappattadhu.');
      case 'home':
        return _tr(loc, 'Returning to Home Dashboard.', 'Home पर वापस आ गए हैं.\nHome par waapas aa gaye hain.', 'Home ಗೆ ಹಿಂತಿರುಗಲಾಗಿದೆ.\nHome ge hinthirugalaagide.', 'Home కి వచ్చాము.\nHome ki vacchaamu.', 'Home க்கு திரும்பியாச்சு.\nHome kku thirumbiyaachu.');
      case 'going_back':
        return _tr(loc, 'Going back.', 'पीछे जा रहे हैं.\nPiche ja rahe hain.', 'ಹಿಂದೆ ಹೋಗಲಾಗುತ್ತಿದೆ.\nHinde hogalaaguttide.', 'వెనక్కి వెళ్తున్నాము.\nVenakki velthunnamu.', 'பின்னால் செல்கிறது.\nPinnaal selgiradhu.');
      case 'visual_assistance':
        return _tr(loc, 'Opening Visual Assistance.', 'Visual Assistance खोल दिया गया है.\nVisual Assistance khol diya gaya hai.', 'Visual Assistance ತೆರೆಯಲಾಗಿದೆ.\nVisual Assistance tereyalaagide.', 'Visual Assistance తెరవబడింది.\nVisual Assistance teravabadindi.', 'Visual Assistance திறக்கப்பட்டது.\nVisual Assistance thirakkappattadhu.');
      case 'hearing_assistance':
        return _tr(loc, 'Opening Hearing Helper.', 'Hearing Helper खोल दिया गया है.\nHearing Helper khol diya gaya hai.', 'Hearing Helper ತೆರೆಯಲಾಗಿದೆ.\nHearing Helper tereyalaagide.', 'Hearing Helper తెరవబడింది.\nHearing Helper teravabadindi.', 'Hearing Helper திறக்கப்பட்டது.\nHearing Helper thirakkappattadhu.');
      case 'speech_assistance':
        return _tr(loc, 'Opening Speech AI Assistant.', 'Speech Assistant खोल दिया गया है.', 'Speech Assistant ತೆರೆಯಲಾಗಿದೆ.', 'Speech Assistant తెరవబడింది.', 'Speech Assistant திறக்கப்பட்டது.');
      case 'emergency':
        return _tr(loc, 'Opening Emergency SOS.', 'Emergency SOS खोल दिया गया है.\nEmergency SOS khol diya gaya hai.', 'Emergency SOS ತೆರೆಯಲಾಗಿದೆ.\nEmergency SOS tereyalaagide.', 'Emergency SOS తెరవబడింది.\nEmergency SOS teravabadindi.', 'Emergency SOS திறக்கப்பட்டது.\nEmergency SOS thirakkappattadhu.');
      case 'navigation':
        return _tr(loc, 'Opening GPS Navigation Helper.', 'Navigation खोल दिया गया है.', 'Navigation ತೆರೆಯಲಾಗಿದೆ.', 'Navigation తెరవబడింది.', 'Navigation திறக்கப்பட்டது.');
      case 'cognitive_assistance':
        return _tr(loc, 'Opening Cognitive Assistance.', 'Cognitive Assistance खोल दिया गया है.\nCognitive Assistance khol diya gaya hai.', 'Cognitive Assistance ತೆರೆಯಲಾಗಿದೆ.\nCognitive Assistance tereyalaagide.', 'Cognitive Assistance తెరవబడింది.\nCognitive Assistance teravabadindi.', 'Cognitive Assistance திறக்கப்பட்டது.\nCognitive Assistance thirakkappattadhu.');
      case 'daily_tasks':
        return _tr(loc, 'Opening Daily Tasks.', 'Daily Tasks खोल दिया गया है.', 'Daily Tasks ತೆರೆಯಲಾಗಿದೆ.', 'Daily Tasks తెరవబడింది.', 'Daily Tasks திறக்கப்பட்டது.');
      case 'reminders':
        return _tr(loc, 'Opening Reminders.', 'Reminders खोल दिया गया है.', 'Reminders ತೆರೆಯಲಾಗಿದೆ.', 'Reminders తెరవబడింది.', 'Reminders திறக்கப்பட்டது.');
      case 'notes':
        return _tr(loc, 'Opening Notes.', 'Notes खोल दिया गया है.', 'Notes ತೆರೆಯಲಾಗಿದೆ.', 'Notes తెరవబడింది.', 'Notes திறக்கப்பட்டது.');
      case 'profile':
        return _tr(loc, 'Opening Profile.', 'Profile खोल दिया गया है.', 'Profile ತೆರೆಯಲಾಗಿದೆ.', 'Profile తెరవబడింది.', 'Profile திறக்கப்பட்டது.');
      case 'translator':
        return _tr(loc, 'Opening Translator.', 'Translator खोल दिया गया है.\nTranslator khol diya gaya hai.', 'Translator ತೆರೆಯಲಾಗಿದೆ.\nTranslator tereyalaagide.', 'Translator తెరవబడింది.\nTranslator teravabadindi.', 'Translator திறக்கப்பட்டது.\nTranslator thirakkappattadhu.');
      case 'settings':
        return _tr(loc, 'Opening Settings.', 'Settings खोल दिया गया है.', 'Settings ತೆರೆಯಲಾಗಿದೆ.', 'Settings తెరవబడింది.', 'Settings திறக்கப்பட்டது.');
      case 'physical_assistance':
        return _tr(loc, 'Opening Physical Assistance.', 'Physical Assistance खोल दिया गया है.\nPhysical Assistance khol diya gaya hai.', 'Physical Assistance ತೆರೆಯಲಾಗಿದೆ.\nPhysical Assistance tereyalaagide.', 'Physical Assistance తెరవబడింది.\nPhysical Assistance teravabadindi.', 'Physical Assistance திறக்கப்பட்டது.\nPhysical Assistance thirakkappattadhu.');
      case 'normal_user':
        return _tr(loc, 'Opening Normal User Suite.', 'Normal User खोल दिया गया है.', 'Normal User ತೆರೆಯಲಾಗಿದೆ.', 'Normal User తెరవబడింది.', 'Normal User திறக்கப்பட்டது.');
      case 'sign_language':
        return _tr(loc, 'Opening Sign Language Translator.', 'Sign Language खोल दिया गया है.', 'Sign Language ತೆರೆಯಲಾಗಿದೆ.', 'Sign Language తెరవబడింది.', 'Sign Language திறக்கப்பட்டது.');
      case 'object_detection':
        return _tr(loc, 'Opening Object Detection.', 'Object Detection खोल दिया गया है.', 'Object Detection ತೆರೆಯಲಾಗಿದೆ.', 'Object Detection తెరవబడింది.', 'Object Detection திறக்கப்பட்டது.');
      case 'ocr':
        return _tr(loc, 'Opening OCR Text Reader.', 'OCR Text Reader खोल दिया गया है.', 'OCR Text Reader ತೆರೆಯಲಾಗಿದೆ.', 'OCR Text Reader తెరవబడింది.', 'OCR Text Reader திறக்கப்பட்டது.');
      case 'scene_description':
        return _tr(loc, 'Opening Scene Description.', 'Scene Description खोल दिया गया है.', 'Scene Description ತೆರೆಯಲಾಗಿದೆ.', 'Scene Description తెరవబడింది.', 'Scene Description திறக்கப்பட்டது.');
      default:
        return _tr(loc, 'Opening module.', 'मॉड्यूल खोल दिया गया है.', 'ವಿಭಾಗ ತೆರೆಯಲಾಗಿದೆ.', 'మాడ్యూల్ తెరవబడింది.', 'திறக்கப்பட்டது.');
    }
  }

  static String micPermissionRequired(String? localeId) {
    return _tr(
      normalizeLocale(localeId),
      'Microphone permission is required for voice control.',
      'वॉयस कंट्रोल के लिए माइक्रोफ़ोन की अनुमति आवश्यक है।\nVoice control ke liye microphone ki anumati aavashyak hai.',
      'ಧ್ವನಿ ನಿಯಂತ್ರಣಕ್ಕೆ ಮೈಕ್ರೋಫೋನ್ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ.\nDhvani niyantranakke microphone anumati agatyavide.',
      'వాయిస్ కంట్రోల్ కోసం మైక్రోఫోన్ అనుమతి అవసరం.\nVoice control kosam microphone anumati avasaram.',
      'குரல் கட்டுப்பாட்டுக்கு மைக்ரோஃபோன் அனுமதி தேவை.\nKural kattuppaattukku microphone anumadhi thevai.',
    );
  }

  static String speechUnavailable(String? localeId) {
    return _tr(
      normalizeLocale(localeId),
      'Speech recognition is unavailable on this device.',
      'इस उपकरण पर भाषण पहचान उपलब्ध नहीं है।',
      'ಈ ಸಾಧನದಲ್ಲಿ ಧ್ವನಿ ಗುರುತಿಸುವಿಕೆ ಲಭ್ಯವಿಲ್ಲ.',
      'ఈ పరికరంలో వాయిస్ నిరూపణ అందుబాటులో లేదు.',
      'இந்த சாதனத்தில் குரல் அங்கீகாரம் இல்லை.',
    );
  }

  static String unrecognizedCommand(String command, String? localeId) {
    final loc = normalizeLocale(localeId);
    switch (loc) {
      case 'hi-IN':
        return 'कमांड पहचानी नहीं गई: "$command"। कृपया दोबारा बोलें।\nCommand pehchaani nahi gayi: "$command". Kripya dobaara bolein.';
      case 'kn-IN':
        return 'ಆಜ್ಞೆ ಅರ್ಥವಾಗಲಿಲ್ಲ: "$command". ದಯವಿಟ್ಟು ಪುನರಾವರ್ತಿಸಿ.\nAagne arthavaagalilla: "$command". Dayavittu punaraavartisi.';
      case 'te-IN':
        return 'కమాండ్ గుర్తించబడలేదు: "$command". దయచేసి మళ్లీ చెప్పండి.\nCommand gurthinchabadaledhu: "$command". Dayachesi malli cheppandi.';
      case 'ta-IN':
        return 'கட்டளை புரியவில்லை: "$command". தயவுசெய்து மீண்டும் சொல்லுங்கள்.\nKattalai puriyavillai: "$command". Thayavuseidhu meendum sollungal.';
      default:
        return 'Command not recognized: "$command". Please repeat.';
    }
  }

  static String getStartupWelcome(String? localeId) => welcomeMessage(localeId);

  static String? getSilencePrompt(String? localeId, int count) {
    return null;
  }

  static String getHelpText(String? localeId) => helpMessage(localeId);

  static String getLanguageChangedConfirmation(String? localeId) => languageChangedConfirmation(localeId);

  static String _tr(String loc, String en, String hi, String kn, String te, String ta) {
    switch (loc) {
      case 'hi-IN':
        return hi;
      case 'kn-IN':
        return kn;
      case 'te-IN':
        return te;
      case 'ta-IN':
        return ta;
      default:
        return en;
    }
  }

  // ==================== 15 CONVERSATIONAL DATASET CATEGORIES REGISTRY ====================
  static final List<MultilingualPhrase> conversationalPhrases = [
    // CAT 1 — BASIC CONVERSATION
    const MultilingualPhrase(
      intent: 'BASIC_CONVERSATION_GREETING',
      category: 'basic_conversation',
      englishText: 'Hello! I am ADIUVA. How can I help you today?',
      nativeTextMap: {
        'ta': 'வணக்கம்! நான் ADIUVA. இன்று உங்களுக்கு நான் எப்படி உதவட்டும்?',
        'te': 'నమస్కారం! నేను ADIUVA. ఈరోజు నేను మీకు ఎలా సహాయపడగలను?',
        'kn': 'ನಮಸ್ಕಾರ! ನಾನು ADIUVA. ಇಂದು ನಾನು ನಿಮಗೆ ಹೇಗೆ ಸಹಾಯ ಮಾಡಲಿ?',
        'hi': 'नमस्ते! मैं ADIUVA हूँ। आज मैं आपकी क्या मदद कर सकता हूँ?',
      },
      transliterationMap: {
        'ta': 'Vanakkam! Naan ADIUVA. Indru ungalukku naan eppadi udhavattum?',
        'te': 'Namaskaram! Nenu ADIUVA. Eeroju nenu meeku elaa sahaayapadagalanu?',
        'kn': 'Namaskara! Naanu ADIUVA. Indhu naanu nimage hege sahaaya maadali?',
        'hi': 'Namaste! Main ADIUVA hoon. Aaj main aapki kya madad kar sakta hoon?',
      },
      aliasesMap: {
        'en': ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening', 'how are you', 'nice to meet you'],
        'ta': ['vanakkam', 'வணக்கம்', 'நலம் தானா', 'நல்ல காலை', 'ஹலோ'],
        'te': ['namaskaram', 'నమస్కారం', 'బాగున్నారా', 'హలో', 'శుభోదయం'],
        'kn': ['namaskara', 'ನಮಸ್ಕಾರ', 'ಹೇಗಿದ್ದೀರಿ', 'ಹಲೋ', 'ಶುಭೋದಯ'],
        'hi': ['namaste', 'नमस्ते', 'कैसे हैं', 'हेलो', 'शुभप्रभात'],
      },
    ),

    // CAT 2 — BASIC NEEDS
    const MultilingualPhrase(
      intent: 'BASIC_NEEDS_HUNGRY',
      category: 'basic_needs',
      englishText: 'I understand you are hungry. Would you like me to set a meal reminder or call your caregiver?',
      nativeTextMap: {
        'ta': 'உங்களுக்கு பசிக்கிறது என்பதை புரிகிறேன். உணவு நினைவூட்டல் அமைக்கவா அல்லது கேர்கிவரை அழைக்கவா?',
        'te': 'మీకు ఆకలిగా ఉందని అర్థమైంది. భోజన రిమైండర్ పెట్టమంటారా లేదా కేర్‌గివర్‌కి కాల్ చేయమంటారా?',
        'kn': 'ನಿಮಗೆ ಹಸಿವಾಗಿದೆ ಎಂದು ಅರ್ಥವಾಯಿತು. ಊಟದ ಜ್ಞಾಪನೆ ಹೊಂದಿಸಲೇ ಅಥವಾ ಕೇರ್‌ಗಿವರ್‌ಗೆ ಕರೆ ಮಾಡಲೇ?',
        'hi': 'मुझे समझ आया कि आपको भूख लगी है। क्या मैं खाना खाने का रिमाइंडर लगाऊँ या केयरगिवर को कॉल करूँ?',
      },
      transliterationMap: {
        'ta': 'Ungalukku pasikkiradhu enbadhai purigiren. Unavu ninaivoottal amaikkavaa alladhu caregiver-ai alaikkavaa?',
        'te': 'Meeku aakaligaa undani arthamaindi. Bhojana reminder pettamantaraa leda caregiver-ki call cheyamantaraa?',
        'kn': 'Nimage hasivaagide endhu arthavaayithu. Ootada jnaapane hondhisalee athava caregiver-ge kare maadalee?',
        'hi': 'Mujhe samajh aaya ki aapko bhookh lagi hai. Kya main khana khane ka reminder lagaun ya caregiver ko call karun?',
      },
      aliasesMap: {
        'en': ['i am hungry', 'i need food', 'hungry', 'need food', 'want food', 'i want to eat'],
        'ta': ['enakku pasikkiradhu', 'எனக்கு பசிக்கிறது', 'பசி', 'உணவு வேண்டும்', 'சாப்பாடு வேண்டும்'],
        'te': ['naaku aakaligaa undhi', 'నాకు ఆకలిగా ఉంది', 'ఆకలి', 'అన్నం కావాలి', 'తిండి కావాలి'],
        'kn': ['nanage hasivaagide', 'ನನಗೆ ಹಸಿವಾಗಿದೆ', 'ಹಸಿವು', 'ಊಟ ಬೇಕು', 'ಆಹಾರ ಬೇಕು'],
        'hi': ['mujhe bhookh lagi hai', 'मुझे भूख लगी है', 'खाना चाहिए', 'भूख'],
      },
    ),

    const MultilingualPhrase(
      intent: 'BASIC_NEEDS_THIRSTY',
      category: 'basic_needs',
      englishText: 'Please drink water and rest. I can remind you to stay hydrated.',
      nativeTextMap: {
        'ta': 'தயவுசெய்து தண்ணீர் குடியுங்கள். நீர் அருந்த நினைவூட்டல் அமைக்கவா?',
        'te': 'దయచేసి మంచి నీళ్ళు తాగండి. నేను నీళ్ళు తాగమని రిమైండర్ పెట్టమంటారా?',
        'kn': 'ದಯವಿಟ್ಟು ನೀರು குடிರಿ. ನೀರು ಕುಡಿಯಲು ಜ್ಞಾಪನೆ ಹೊಂದಿಸಲೇ?',
        'hi': 'कृपया पानी पिएं और आराम करें। क्या मैं पानी पीने का रिमाइंडर लगाऊँ?',
      },
      transliterationMap: {
        'ta': 'Thayavuseydhu thanneer kudiyungal. Neer arundha ninaivoottal amaikkavaa?',
        'te': 'Dayachesi manchi neellu thaagandi. Nenu neellu thaagamani reminder pettamantaraa?',
        'kn': 'Dayavittu neeru kudiri. Neeru kudiyalu jnaapane hondhisalee?',
        'hi': 'Kripya paani pien aur aaram karein. Kya main paani peene ka reminder lagaun?',
      },
      aliasesMap: {
        'en': ['i am thirsty', 'i need water', 'thirsty', 'need water', 'water please'],
        'ta': ['enakku thaagam', 'எனக்கு தாகமாக இருக்கிறது', 'தண்ணீர் வேண்டும்', 'தாகம்'],
        'te': ['naaku daahamgaa undhi', 'నాకు దాహంగా ఉంది', 'నీళ్ళు కావాలి', 'దాహం'],
        'kn': ['nanage dhaahavaagide', 'ನನಗೆ ದಾಹವಾಗಿದೆ', 'ನೀರು ಬೇಕು', 'ದಾಹ'],
        'hi': ['mujhe pyaas lagi hai', 'मुझे प्यास लगी है', 'पानी चाहिए', 'प्यास'],
      },
    ),

    const MultilingualPhrase(
      intent: 'BASIC_NEEDS_TIRED',
      category: 'basic_needs',
      englishText: 'Please take rest. Would you like me to pause continuous voice recognition?',
      nativeTextMap: {
        'ta': 'தயவுசெய்து ஓய்வெடுங்கள். குரல் அறிதலை சிறிது நேரம் நிறுத்தவா?',
        'te': 'దయచేసి విశ్రాంతి తీసుకోండి. వాయిస్ గురింపును కాసేపు ఆపమంటారా?',
        'kn': 'ದಯವಿಟ್ಟು ವಿಶ್ರಾಂತಿ ತೆಗೆದುಕೊಳ್ಳಿ. ಧ್ವನಿ ಗುರುತಿಸುವಿಕೆಯನ್ನು ತಡೆಯಲೇ?',
        'hi': 'कृपया आराम करें। क्या मैं वॉयस कंट्रोल को थोड़ी देर रोक दूँ?',
      },
      transliterationMap: {
        'ta': 'Thayavuseydhu oyvedungal. Kural aridhalai siridhu neram niruthavaa?',
        'te': 'Dayachesi vishraanthi theusukondi. Voice gurimpunu kaasepu aapamantaraa?',
        'kn': 'Dayavittu vishraanthi thegedukolli. Dhvani guruthisuvikeyannu thadeyalee?',
        'hi': 'Kripya aaram karein. Kya main voice control ko thodi der rok doon?',
      },
      aliasesMap: {
        'en': ['i am tired', 'i need rest', 'tired', 'feeling sleepy', 'need sleep'],
        'ta': ['enakku kalaippaaga irukkiradhu', 'எனக்கு களைப்பாக இருக்கிறது', 'ஓய்வு வேண்டும்', 'தூக்கம் வருது'],
        'te': ['naaku alaasathagaa undhi', 'నాకు అలసటగా ఉంది', 'విశ్రాంతి కావాలి', 'నిద్ర వస్తోంది'],
        'kn': ['nanage aayasavaagide', 'ನನಗೆ ಆಯಾಸವಾಗಿದೆ', 'ವಿಶ್ರಾಂತಿ ಬೇಕು', 'ನಿದ್ರೆ ಬರುತ್ತಿದೆ'],
        'hi': ['main thak gaya hoon', 'मुझे थकान हो रही है', 'आराम चाहिए', 'नींद आ रही है'],
      },
    ),

    // CAT 3 — UNDERSTANDING / CONTROL
    const MultilingualPhrase(
      intent: 'UNDERSTANDING_REPEAT',
      category: 'understanding_control',
      englishText: 'I will repeat the last response for you.',
      nativeTextMap: {
        'ta': 'கடைசி பதிலை மீண்டும் சொல்கிறேன்.',
        'te': 'చివరి సమాధానాన్ని మళ్ళీ చెప్తున్నాను.',
        'kn': 'ಕೊನೆಯ ಉತ್ತರವನ್ನು ಮತ್ತೆ ಹೇಳುತ್ತಿದ್ದೇನೆ.',
        'hi': 'मैं आखिरी उत्तर दोबारा बोलता हूँ।',
      },
      transliterationMap: {
        'ta': 'Kadaisi padhilai meendum solgiren.',
        'te': 'Chivari samaadhananni malli cheptunnanu.',
        'kn': 'Koneya uttharavannu matthe heluththedhene.',
        'hi': 'Main aakhri uttar dobara bolta hoon.',
      },
      aliasesMap: {
        'en': ['what did you say', 'repeat that', 'please repeat', 'say again', 'pardon'],
        'ta': ['enna sonneengal', 'என்ன சொன்னீர்கள்', 'மீண்டும் சொல்', 'மறுபடியும் சொல்'],
        'te': ['emi cheppaaru', 'ఏమి చెప్పారు', 'మళ్ళీ చెప్పండి', 'మళ్ళీ అనండి'],
        'kn': ['en helidri', 'ಏನು ಹೇಳಿದ್ರಿ', 'ಮತ್ತೆ ಹೇಳಿ', 'ಇನ್ನೊಮ್ಮೆ ಹೇಳಿ'],
        'hi': ['kya kaha aapne', 'क्या कहा आपने', 'दोबारा बोलिए', 'फिर से कहो'],
      },
    ),

    // CAT 4 — QUESTIONS
    const MultilingualPhrase(
      intent: 'QUESTIONS_TIME',
      category: 'questions',
      englishText: 'I am checking the current time for you.',
      nativeTextMap: {
        'ta': 'தற்போதைய நேரத்தை பார்க்கிறேன்.',
        'te': 'ప్రస్తుత సమయాన్ని చూస్తున్నాను.',
        'kn': 'ಪ್ರಸ್ತುತ ಸಮಯವನ್ನು ಪರಿಶೀಲಿಸುತ್ತಿದ್ದೇನೆ.',
        'hi': 'मैं अभी का समय देख रहा हूँ।',
      },
      transliterationMap: {
        'ta': 'Tharpoathaiya nerathai paarkkiren.',
        'te': 'Prastuta samayaanni choostunnanu.',
        'kn': 'Prastuta samayavannu parishilisuththedhene.',
        'hi': 'Main abhi ka samay dekh raha hoon.',
      },
      aliasesMap: {
        'en': ['what time is it', 'tell me time', 'current time', 'what is the time'],
        'ta': ['mani enna', 'மணி என்ன', 'நேரம் என்ன', 'இப்போது என்ன மணி'],
        'te': ['time entha ayindi', 'టైమ్ ఎంత అయింది', 'సమయం ఎంత', 'ఇప్పుడు టైమ్ ఎంత'],
        'kn': ['time eshtu aaythu', 'ಟೈಮ್ ಎಷ್ಟು ಆಯ್ತು', 'ಸಮಯ ಎಷ್ಟು', 'ಈಗ ಎಷ್ಟು ಗಂಟೆ'],
        'hi': ['kitne baje hain', 'कितने बजे हैं', 'समय क्या हुआ', 'टाइम क्या है'],
      },
    ),

    // CAT 6 — SOCIAL PHRASES & CONFIRMATIONS
    const MultilingualPhrase(
      intent: 'SOCIAL_THANK_YOU',
      category: 'social_phrases',
      englishText: 'You are very welcome! I am always here to assist you.',
      nativeTextMap: {
        'ta': 'மிக்க மகிழ்ச்சி! உங்களுக்கு உதவ நான் எப்போதும் தயார்.',
        'te': 'చాలా సంతోషం! మీకు సహాయం చేయడానికి నేను ఎల్లప్పుడూ ఇక్కడే ఉన్నాను.',
        'kn': 'ತುಂಬಾ ಸಂತೋಷ! ನಿಮಗೆ ನೆರವಾಗಲು ನಾನು ಯಾವಾಗಲೂ ಇಲ್ಲಿದ್ದೇನೆ.',
        'hi': 'आपका बहुत स्वागत है! मैं आपकी मदद के लिए हमेशा तैयार हूँ।',
      },
      transliterationMap: {
        'ta': 'Mikka magizhchi! Ungalukku udhava naan eppodhum thayaar.',
        'te': 'Chaala santhosham! Meeku sahaayam cheyadaaniki nenu ellappudoo ikkade unnaanu.',
        'kn': 'Thumba santhosha! Nimage neravaagalu naanu yaavaagaloo illiddhene.',
        'hi': 'Aapka bahut swagat hai! Main aapki madad ke liye hamesha taiyar hoon.',
      },
      aliasesMap: {
        'en': ['thank you', 'thanks', 'thank you so much', 'thanks a lot'],
        'ta': ['nandri', 'நன்றி', 'மிக்க நன்றி', 'ரொம்ப நன்றி'],
        'te': ['dhanyavaadalu', 'ధన్యవాదాలు', 'చాలా థాంక్స్', 'థాంక్యూ'],
        'kn': ['dhanyavaadagalu', 'ಧನ್ಯವಾದಗಳು', 'ತುಂಬಾ ಧನ್ಯವಾದ', 'ಥ್ಯಾಂಕ್ಸ್'],
        'hi': ['dhanyavaad', 'धन्यवाद', 'शुक्रिया', 'बहुत धन्यवाद'],
      },
    ),

    // CAT 10 — EMOTIONAL EXPRESSIONS
    const MultilingualPhrase(
      intent: 'EMOTIONAL_HAPPY',
      category: 'emotional_expressions',
      englishText: 'I am so glad to hear that you are feeling good!',
      nativeTextMap: {
        'ta': 'நீங்கள் மகிழ்ச்சியாக இருப்பதை கேட்டு எனக்கு மிக்க சந்தோஷம்!',
        'te': 'మీరు సంతోషంగా ఉన్నారని వినడం చాలా ఆనందంగా ఉంది!',
        'kn': 'ನೀವು ಸಂತೋಷವಾಗಿದ್ದೀರಿ ಎಂದು ಕೇಳಿ ನನಗೆ ತುಂಬಾ ಖುಷಿಯಾಯಿತು!',
        'hi': 'यह जानकर मुझे बहुत खुशी हुई कि आप अच्छा महसूस कर रहे हैं!',
      },
      transliterationMap: {
        'ta': 'Neengal magizhchiyaaga iruppadhai kaettu enakku mikka santhosham!',
        'te': 'Meeru santhoshangaa unnaraani vinadam chaala aanandangaa undhi!',
        'kn': 'Neevu santhoshavaagiddeeri endhu keli nanage thumba khushiyaayithu!',
        'hi': 'Yeh jaankar mujhe bahut khushi hui ki aap achha mehsus kar rahe hain!',
      },
      aliasesMap: {
        'en': ['i am happy', 'i feel good', 'feeling great', 'i am fine'],
        'ta': ['naan magizhchiyaaga irukkiren', 'நான் மகிழ்ச்சியாக இருக்கிறேன்', 'சந்தோஷம்', 'நல்லா இருக்கேன்'],
        'te': ['nenu santhoshangaa unnanu', 'నేను సంతోషంగా ఉన్నాను', 'హ్యాపీగా ఉన్నా', 'బాగున్నాను'],
        'kn': ['naanu khushiyaagiddene', 'ನಾನು ಖುಷಿಯಾಗಿದ್ದೇನೆ', 'ಸಂತೋಷ', 'ಚೆನ್ನಾಗಿದ್ದೇನೆ'],
        'hi': ['main khush hoon', 'मैं खुश हूँ', 'अच्छा लग रहा है', 'बढ़िया'],
      },
    ),
  ];

  /// Resolve any input string against Layer 2 Conversational phrases
  static MultilingualPhrase? resolveConversationalPhrase(String rawTranscript, String? localeId) {
    final cleanInput = rawTranscript.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
    if (cleanInput.isEmpty) return null;

    final activeLang = normalizeLocale(localeId).split('-').first;

    for (final phrase in conversationalPhrases) {
      // 1. Check active language aliases
      final aliases = phrase.aliasesMap[activeLang] ?? [];
      for (final alias in aliases) {
        final cleanAlias = alias.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
        if (cleanInput == cleanAlias || (cleanAlias.length >= 4 && cleanInput.contains(cleanAlias))) {
          return phrase;
        }
      }

      // 2. Fallback check all other languages aliases
      for (final langEntry in phrase.aliasesMap.entries) {
        if (langEntry.key == activeLang) continue;
        for (final alias in langEntry.value) {
          final cleanAlias = alias.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
          if (cleanInput == cleanAlias || (cleanAlias.length >= 5 && cleanAlias.contains(' ') && cleanInput.contains(cleanAlias))) {
            return phrase;
          }
        }
      }
    }
    return null;
  }
}


/// Centralized Language Command Parser for ADIUVA Global Voice Control
class LanguageCommandParser {
  /// Parse raw/normalized speech input and return target language code ('en', 'hi', 'kn', 'te', 'ta') if a language-switch command is recognized, or null otherwise.
  static String? parseTargetLanguage(String rawInput) {
    final clean = rawInput.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
    if (clean.isEmpty) return null;

    // Filter out TTS feedback/confirmation phrases so they are never parsed as user language commands
    if (clean.contains('language changed') ||
        clean.contains('already active') ||
        clean.contains('మాచ్') ||
        clean.contains('మార్చాను') ||
        clean.contains('ప్రస్తుతం') ||
        clean.contains('மாற்றப்பட்டது') ||
        clean.contains('ஏற்கனவே') ||
        clean.contains('ಬದಲಾಯಿಸಲಾಗಿದೆ') ||
        clean.contains('ಈಗಾಗಲೇ') ||
        clean.contains('बदल दी गई') ||
        clean.contains('पहले से')) {
      return null;
    }

    // 1. Identify Target Language across Latin, Native Regional Scripts, and Cross-Script STT Transliterations
    String? targetCode;

    // Tamil (tamil/thamil/tamel/taml | Tamil script: தமிழ் | Telugu script: తమిళ,మిళ్,మిళం | Kannada script: ತಮಿಳು | Hindi script: तमिल,तमिळ)
    if (clean.contains('tamil') || clean.contains('thamil') || clean.contains('tamel') || clean.contains('taml') ||
        clean.contains('தமிழ்') || clean.contains('தமி') ||
        clean.contains('తమిళ') || clean.contains('తమిళ్') || clean.contains('తమిళం') ||
        clean.contains('ತಮಿಳು') || clean.contains('ತಮಿಳ್') ||
        clean.contains('तमिल') || clean.contains('तमिळ')) {
      targetCode = 'ta';
    }
    // Telugu (telugu/telgu/telegu | Telugu script: తెలుగు | Tamil script: தெலுங்கு | Kannada script: ತೆಲುಗು | Hindi script: तेलुगु)
    else if (clean.contains('telugu') || clean.contains('telgu') || clean.contains('telegu') ||
        clean.contains('తెలుగు') ||
        clean.contains('தெலுங்கு') || clean.contains('தெலுகு') ||
        clean.contains('ತೆಲುಗು') ||
        clean.contains('तेलुगु')) {
      targetCode = 'te';
    }
    // Kannada (kannada/kanada/kannad | Kannada script: ಕನ್ನಡ | Telugu script: కన్నడ | Tamil script: கன்னடம் | Hindi script: कन्नड़)
    else if (clean.contains('kannada') || clean.contains('kanada') || clean.contains('kannad') ||
        clean.contains('ಕನ್ನಡ') ||
        clean.contains('కన్నడ') ||
        clean.contains('கன்னடம்') || clean.contains('கன்னட') ||
        clean.contains('कन्नड़') || clean.contains('कन्नड')) {
      targetCode = 'kn';
    }
    // Hindi (hindi/hind/hindhi | Hindi script: हिंदी,हिन्दी | Telugu script: హిందీ | Tamil script: ஹிந்தி,இந்தி | Kannada script: ಹಿಂದಿ)
    else if (clean.contains('hindi') || clean.contains('hind') ||
        clean.contains('हिन्दी') || clean.contains('हिंदी') || clean.contains('हिंद') ||
        clean.contains('హిందీ') || clean.contains('హింధీ') ||
        clean.contains('ஹிந்தி') || clean.contains('இந்தி') ||
        clean.contains('ಹಿಂದಿ')) {
      targetCode = 'hi';
    }
    // English (english/inglish/angrezi | Telugu script: ఇంగ్లీష్,ఇంగ్లీషు,ఆంగ్లం | Tamil script: இங்கிலீஷ்,ஆங்கிலம் | Kannada script: ಇಂಗ್ಲಿಷ್,ಆಂಗ್ಲ | Hindi script: अंग्रेजी,इंग्लिश)
    else if (clean.contains('english') || clean.contains('angrezi') || clean.contains('inglish') || clean.contains('angresi') ||
        clean.contains('இங்கிலீஷ்') || clean.contains('ஆங்கிலம்') || clean.contains('இங்கி') ||
        clean.contains('ఇంగ్లీష్') || clean.contains('ఇంగ్లీషు') || clean.contains('ఇంగ్లిష్') || clean.contains('ఆంగ్లం') || clean.contains('ఇంగ్లీ') ||
        clean.contains('ಇಂಗ್ಲಿಷ್') || clean.contains('ಆಂಗ್ಲ') || clean.contains('ಇಂಗ್ಲಿ') ||
        clean.contains('अंग्रेजी') || clean.contains('इंग्लिश') || clean.contains('अंगर') || clean.contains('इंग्ल')) {
      targetCode = 'en';
    }

    if (targetCode == null) return null;

    // Rule 7: If the transcript contains a clear target language token, prioritize target language
    // Check direct single word / short phrase invocation or presence of any action trigger in any script
    final actionTriggers = [
      'change', 'switch', 'set', 'convert', 'turn', 'select', 'make',
      'bhasha', 'mozhi', 'bhashe', 'cheyyi', 'pannu', 'maadi', 'marchu', 'maathu',
      'badalisi', 'badlo', 'karo', 'language', 'mein', 'me', 'to', 'ki', 'ku', 'ge', 'se', 'lo', 'la',
      'చేంజ్', 'స్విచ్', 'లాంగ్వేజ్', 'మార్చు', 'భాష', 'చేయి', 'టు',
      'சேஞ்ச்', 'ஸ்விட்ச்', 'லாங்குவேஜ்', 'மாற்று', 'மாத்து', 'மொழி', 'டு',
      'ಚೇಂಜ್', 'ಸ್ವಿಚ್', 'ಲ್ಯಾಂಗ್ವೇಜ್', 'ಬದಲಾಯಿಸಿ', 'ಭಾಷೆ', 'ಟು',
      'चेंज', 'स्विच', 'लैंग्वेज', 'बदलो', 'बदलें', 'भाषा', 'टू'
    ];

    // If any action trigger is found, OR if clean length is short (language name spoken directly)
    if (clean.split(' ').length <= 4) {
      return targetCode;
    }

    for (final trigger in actionTriggers) {
      if (clean.contains(trigger)) {
        return targetCode;
      }
    }

    return targetCode;
  }
}
