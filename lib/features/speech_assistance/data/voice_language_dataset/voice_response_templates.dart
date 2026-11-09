import 'global_voice_intents.dart';

/// Localized Response Model (Native TOP, Transliteration UNDERNEATH, TTS Native ONLY)
class VoiceResponseTemplate {
  final String nativeText;
  final String transliterationText;
  final String ttsText;

  const VoiceResponseTemplate({
    required this.nativeText,
    required this.transliterationText,
    required this.ttsText,
  });

  /// Formats UI display string with dual representation for regional languages
  String get displayString {
    if (transliterationText.trim().isEmpty) return nativeText;
    return '$nativeText\n$transliterationText';
  }
}

/// Centralized Localized System Voice Response Templates & Location Hierarchy Formatter
class VoiceResponseTemplates {
  /// Format Location response enforcing human-readable geographic hierarchy:
  /// Village → Post → City/Town → Taluk/Mandal → District → State → Country
  /// Eliminates raw PIN codes, plus codes, house numbers, lat/long, and malformed fragments.
  static String formatCleanLocationAddress(String rawAddress) {
    if (rawAddress.trim().isEmpty) return '';

    // Filter out raw Plus Codes (e.g., Q900+7, Q975+H38) and raw lat-long digits
    final cleaned = rawAddress
        .replaceAll(RegExp(r'[A-Z0-9]{4,8}\+[A-Z0-9]{2,4}'), '')
        .replaceAll(RegExp(r'\b\d{5,6}\b'), '') // Removes standalone 6-digit zip/pin codes
        .replaceAll(RegExp(r'#\d+[\w\s\-]*,?'), '') // Removes house numbers
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final parts = cleaned
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p.length > 2)
        .toList();

    // Deduplicate tokens while maintaining hierarchy order
    final List<String> uniqueParts = [];
    for (final part in parts) {
      if (!uniqueParts.any((existing) => existing.toLowerCase() == part.toLowerCase())) {
        uniqueParts.add(part);
      }
    }

    return uniqueParts.join(', ');
  }

  /// Get localized Location response template for active language
  static VoiceResponseTemplate getLocationResponse({
    required String languageCode,
    required String address,
  }) {
    final cleanAddress = formatCleanLocationAddress(address);
    final lang = languageCode.toLowerCase().split('-').first;

    if (cleanAddress.isEmpty) {
      switch (lang) {
        case 'te':
          return const VoiceResponseTemplate(
            nativeText: 'లొకేషన్ సమాచారం అందుబాటులో లేదు.',
            transliterationText: 'Location samaacharam andhubaatulo ledhu.',
            ttsText: 'లొకేషన్ సమాచారం అందుబాటులో లేదు.',
          );
        case 'ta':
          return const VoiceResponseTemplate(
            nativeText: 'இருப்பிட தகவல் கிடைக்கவில்லை.',
            transliterationText: 'Iruppidha thagaval kidakkavillai.',
            ttsText: 'இருப்பிட தகவல் கிடைக்கவில்லை.',
          );
        case 'kn':
          return const VoiceResponseTemplate(
            nativeText: 'ಸ್ಥಳದ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ.',
            transliterationText: 'Sthalada maahiti labhyavilla.',
            ttsText: 'ಸ್ಥಳದ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ.',
          );
        case 'hi':
          return const VoiceResponseTemplate(
            nativeText: 'लोकेशन की जानकारी उपलब्ध नहीं है।',
            transliterationText: 'Location ki jaankari uplabdh nahi hai.',
            ttsText: 'लोकेशन की जानकारी उपलब्ध नहीं है।',
          );
        default:
          return const VoiceResponseTemplate(
            nativeText: 'Location information is currently unavailable.',
            transliterationText: '',
            ttsText: 'Location information is currently unavailable.',
          );
      }
    }

    switch (lang) {
      case 'te':
        return VoiceResponseTemplate(
          nativeText: 'మీ ప్రస్తుత స్థానం $cleanAddress.',
          transliterationText: 'Mee prastuta sthaanam $cleanAddress.',
          ttsText: 'మీ ప్రస్తుత స్థానం $cleanAddress.',
        );
      case 'ta':
        return VoiceResponseTemplate(
          nativeText: 'உங்கள் தற்போதைய இருப்பிடம் $cleanAddress.',
          transliterationText: 'Ungal tharpoathaiya iruppidam $cleanAddress.',
          ttsText: 'உங்கள் தற்போதைய இருப்பிடம் $cleanAddress.',
        );
      case 'kn':
        return VoiceResponseTemplate(
          nativeText: 'ನಿಮ್ಮ ಪ್ರಸ್ತುತ ಸ್ಥಳ $cleanAddress.',
          transliterationText: 'Nimma prastuta sthala $cleanAddress.',
          ttsText: 'ನಿಮ್ಮ ಪ್ರಸ್ತುತ ಸ್ಥಳ $cleanAddress.',
        );
      case 'hi':
        return VoiceResponseTemplate(
          nativeText: 'आपका वर्तमान स्थान $cleanAddress है।',
          transliterationText: 'Aapka vartamaan sthaan $cleanAddress hai.',
          ttsText: 'आपका वर्तमान स्थान $cleanAddress है।',
        );
      default:
        return VoiceResponseTemplate(
          nativeText: 'Your current location is $cleanAddress.',
          transliterationText: '',
          ttsText: 'Your current location is $cleanAddress.',
        );
    }
  }

  /// Map of default localized execution confirmations by intent and language
  static const Map<String, Map<String, VoiceResponseTemplate>> defaultResponses = {
    GlobalVoiceIntent.goHome: {
      'en': VoiceResponseTemplate(
        nativeText: 'Returning to Home Dashboard.',
        transliterationText: '',
        ttsText: 'Returning to Home Dashboard.',
      ),
      'te': VoiceResponseTemplate(
        nativeText: 'హోమ్ డాష్‌బోర్డ్‌కి తిరిగి వెళ్తున్నాము.',
        transliterationText: 'Home dashboard ki thirigi velthunnamu.',
        ttsText: 'హోమ్ డాష్‌బోర్డ్‌కి తిరిగి వెళ్తున్నాము.',
      ),
      'ta': VoiceResponseTemplate(
        nativeText: 'முகப்பு பக்கத்திற்கு திரும்புகிறது.',
        transliterationText: 'Mugappu pakkathirku thirumbugiradhu.',
        ttsText: 'முகப்பு பக்கத்திற்கு திரும்புகிறது.',
      ),
      'kn': VoiceResponseTemplate(
        nativeText: 'ಹೋಮ್ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್‌ಗೆ ಹಿಂತಿರುಗಲಾಗುತ್ತಿದೆ.',
        transliterationText: 'Home dashboard ge hinthirugalaaguttide.',
        ttsText: 'ಹೋಮ್ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್‌ಗೆ ಹಿಂತಿರುಗಲಾಗುತ್ತಿದೆ.',
      ),
      'hi': VoiceResponseTemplate(
        nativeText: 'होम डैशबोर्ड पर वापस जा रहे हैं।',
        transliterationText: 'Home dashboard par wapas ja rahe hain.',
        ttsText: 'होम डैशबोर्ड पर वापस जा रहे हैं।',
      ),
    },

    GlobalVoiceIntent.openVisualAssistance: {
      'en': VoiceResponseTemplate(
        nativeText: 'Opening Visual Assistance.',
        transliterationText: '',
        ttsText: 'Opening Visual Assistance.',
      ),
      'te': VoiceResponseTemplate(
        nativeText: 'విజ్యువల్ అసిస్టెన్స్ తెరవబడింది.',
        transliterationText: 'Visual assistance teravabadindi.',
        ttsText: 'విజ్యువల్ అసిస్టెన్స్ తెరవబడింది.',
      ),
      'ta': VoiceResponseTemplate(
        nativeText: 'பார்வை உதவி திறக்கப்பட்டது.',
        transliterationText: 'Paarvai udhavi thirakkappattadhu.',
        ttsText: 'பார்வை உதவி திறக்கப்பட்டது.',
      ),
      'kn': VoiceResponseTemplate(
        nativeText: 'ದೃಷ್ಟಿ ನೆರವು ತೆರೆಯಲಾಗಿದೆ.',
        transliterationText: 'Drushti neravu tereyalaagide.',
        ttsText: 'ದೃಷ್ಟಿ ನೆರವು ತೆರೆಯಲಾಗಿದೆ.',
      ),
      'hi': VoiceResponseTemplate(
        nativeText: 'विजुअल असिस्टेंस खोल दिया गया है।',
        transliterationText: 'Visual assistance khol diya gaya hai.',
        ttsText: 'विजुअल असिस्टेंस खोल दिया गया है।',
      ),
    },

    GlobalVoiceIntent.emergencySos: {
      'en': VoiceResponseTemplate(
        nativeText: 'Opening Emergency SOS.',
        transliterationText: '',
        ttsText: 'Opening Emergency SOS.',
      ),
      'te': VoiceResponseTemplate(
        nativeText: 'అత్యవసర ఎస్ఓఎస్ తెరవబడింది.',
        transliterationText: 'Atyavasara SOS teravabadindi.',
        ttsText: 'అత్యవసర ఎస్ఓఎస్ తెరవబడింది.',
      ),
      'ta': VoiceResponseTemplate(
        nativeText: 'அவசர ஆபத்து உதவி திறக்கப்பட்டது.',
        transliterationText: 'Avasara aapathu udhavi thirakkappattadhu.',
        ttsText: 'அவசர ஆபத்து உதவி திறக்கப்பட்டது.',
      ),
      'kn': VoiceResponseTemplate(
        nativeText: 'ತುರ್ತು ಎಸ್ಒಎಸ್ ತೆರೆಯಲಾಗಿದೆ.',
        transliterationText: 'Thurtu SOS tereyalaagide.',
        ttsText: 'ತುರ್ತು ಎಸ್ಒಎಸ್ ತೆರೆಯಲಾಗಿದೆ.',
      ),
      'hi': VoiceResponseTemplate(
        nativeText: 'इमरजेंसी एसओएस खोल दिया गया है।',
        transliterationText: 'Emergency SOS khol diya gaya hai.',
        ttsText: 'इमरजेंसी एसओएस खोल दिया गया है।',
      ),
    },
  };
}
