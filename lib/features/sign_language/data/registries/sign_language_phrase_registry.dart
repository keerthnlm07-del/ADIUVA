import '../../domain/entities/sign_language_phrase.dart';

/// Centralized Phrase Registry for Indian Sign Language (ISL) Animations & Recognition
class SignLanguagePhraseRegistry {
  SignLanguagePhraseRegistry._();

  static const List<SignLanguagePhrase> phrases = [
    SignLanguagePhrase(
      id: 'A',
      displayText: 'Letter A',
      aliases: ['a', 'letter a', 'alphabet a'],
      animationName: 'A',
      assetPath: 'assets/sign_language/alphabet/A_test.jpg',
    ),
    SignLanguagePhrase(
      id: 'B',
      displayText: 'Letter B',
      aliases: ['b', 'letter b', 'alphabet b'],
      animationName: 'B',
      assetPath: 'assets/sign_language/alphabet/B_test.jpg',
    ),
    SignLanguagePhrase(
      id: 'C',
      displayText: 'Letter C',
      aliases: ['c', 'letter c', 'alphabet c'],
      animationName: 'C',
      assetPath: 'assets/sign_language/alphabet/C_test.jpg',
    ),
    SignLanguagePhrase(
      id: 'D',
      displayText: 'Letter D',
      aliases: ['d', 'letter d', 'alphabet d'],
      animationName: 'D',
      assetPath: 'assets/sign_language/alphabet/D_test.jpg',
    ),
    SignLanguagePhrase(
      id: 'hello',
      displayText: 'Hi / Hello',
      aliases: ['hello', 'hi', 'hey', 'greetings', 'नमस्ते', 'నమస్కారం', 'வணக்கம்', 'ನಮಸ್ಕಾರ'],
      animationName: 'HELLO',
      assetPath: 'assets/sign_language/animations/hello.glb',
    ),

    SignLanguagePhrase(
      id: 'good_morning',
      displayText: 'Good morning',
      aliases: ['good morning', 'morning', 'शुभ प्रभात', 'ಶುಭೋದಯ'],
      animationName: 'GOOD_MORNING',
      assetPath: 'assets/sign_language/animations/good_morning.glb',
    ),
    SignLanguagePhrase(
      id: 'how_are_you',
      displayText: 'How are you?',
      aliases: ['how are you', 'how are u', 'how r u', 'how do you do', 'आप कैसे हैं', 'హౌ ఆర్ యు'],
      animationName: 'HOW_ARE_YOU',
      assetPath: 'assets/sign_language/animations/how_are_you.glb',
    ),
    SignLanguagePhrase(
      id: 'thank_you',
      displayText: 'Thank you',
      aliases: ['thank you', 'thanks', 'thank u', 'धन्यवाद', 'ధన్యవాదాలు', 'நன்றி', 'ಧನ್ಯವಾದಗಳು'],
      animationName: 'THANK_YOU',
      assetPath: 'assets/sign_language/animations/thank_you.glb',
    ),
    SignLanguagePhrase(
      id: 'please',
      displayText: 'Please',
      aliases: ['please', 'pls', 'कृपया', 'దయచేసి'],
      animationName: 'PLEASE',
      assetPath: 'assets/sign_language/animations/please.glb',
    ),
    SignLanguagePhrase(
      id: 'sorry',
      displayText: 'Sorry',
      aliases: ['sorry', 'apologies', 'माफ़ कीजिए', 'క్షమించండి'],
      animationName: 'SORRY',
      assetPath: 'assets/sign_language/animations/sorry.glb',
    ),
    SignLanguagePhrase(
      id: 'yes',
      displayText: 'Yes',
      aliases: ['yes', 'yeah', 'yep', 'हाँ', 'అవును', 'ஆம்', 'ಹೌದು'],
      animationName: 'YES',
      assetPath: 'assets/sign_language/animations/yes.glb',
    ),
    SignLanguagePhrase(
      id: 'no',
      displayText: 'No',
      aliases: ['no', 'nope', 'nah', 'नहीं', 'कादु', 'இல்லை', 'ಇಲ್ಲ'],
      animationName: 'NO',
      assetPath: 'assets/sign_language/animations/no.glb',
    ),
    SignLanguagePhrase(
      id: 'help',
      displayText: 'Help',
      aliases: ['help', 'मदद', 'సహాయం', 'உதவி', 'ಸಹಾಯ'],
      animationName: 'HELP',
      assetPath: 'assets/sign_language/animations/help.glb',
    ),
    SignLanguagePhrase(
      id: 'i_need_help',
      displayText: 'I need help',
      aliases: ['i need help', 'need help', 'can you help me', 'help me', 'please help me', 'मुझे मदद चाहिए', 'నాకు సహాయం కావాలి', 'எனக்கு உதவி வேண்டும்', 'ನನಗೆ ಸಹಾಯ ಬೇಕು'],
      animationName: 'I_NEED_HELP',
      assetPath: 'assets/sign_language/animations/i_need_help.glb',
    ),
    SignLanguagePhrase(
      id: 'stop',
      displayText: 'Stop',
      aliases: ['stop', 'halt', 'रुकिए', 'ఆపు', 'நிறுத்து', 'ನಿಲ್ಲಿಸಿ'],
      animationName: 'STOP',
      assetPath: 'assets/sign_language/animations/stop.glb',
    ),
    SignLanguagePhrase(
      id: 'emergency',
      displayText: 'Emergency / SOS',
      aliases: ['emergency', 'sos', 'danger', 'आपातकाल', 'అత్యవసర', 'அவசரம்'],
      animationName: 'EMERGENCY',
      assetPath: 'assets/sign_language/animations/emergency.glb',
    ),
    SignLanguagePhrase(
      id: 'where_am_i',
      displayText: 'Where am I?',
      aliases: ['where am i', 'where is this', 'मैं कहाँ हूँ', 'నేను ఎక్కడ ఉన్నాను'],
      animationName: 'WHERE_AM_I',
      assetPath: 'assets/sign_language/animations/where_am_i.glb',
    ),
    SignLanguagePhrase(
      id: 'location',
      displayText: 'Location',
      aliases: ['location', 'current location', 'स्थान', 'స్థానం', 'இடம்', 'ಸ್ಥಳ'],
      animationName: 'LOCATION',
      assetPath: 'assets/sign_language/animations/location.glb',
    ),
    SignLanguagePhrase(
      id: 'home',
      displayText: 'Home',
      aliases: ['home', 'go home', 'my house', 'घर', 'ఇల్లు', 'வீடு', 'ಮನೆ'],
      animationName: 'HOME',
      assetPath: 'assets/sign_language/animations/home.glb',
    ),
    SignLanguagePhrase(
      id: 'caregiver',
      displayText: 'Caregiver',
      aliases: ['caregiver', 'helper', 'assistant', 'देखभालकर्ता', 'సంరక్షకుడు', 'பராமரிப்பாளர்'],
      animationName: 'CAREGIVER',
      assetPath: 'assets/sign_language/animations/caregiver.glb',
    ),
    SignLanguagePhrase(
      id: 'call_caregiver',
      displayText: 'Call caregiver',
      aliases: ['call caregiver', 'phone caregiver', 'contact caregiver', 'केयरगिवर को कॉल करें', 'సంరక్షకుడికి కాల్ చేయండి'],
      animationName: 'CALL_CAREGIVER',
      assetPath: 'assets/sign_language/animations/call_caregiver.glb',
    ),
    SignLanguagePhrase(
      id: 'water',
      displayText: 'Water',
      aliases: ['water', 'drink water', 'need water', 'पानी', 'నీరు', 'తన్నీరు', 'தண்ணீர்', 'நீரு'],
      animationName: 'WATER',
      assetPath: 'assets/sign_language/animations/water.glb',
    ),
    SignLanguagePhrase(
      id: 'food',
      displayText: 'Food',
      aliases: ['food', 'eat food', 'hungry', 'खाना', 'ఆహారం', 'உணவு', 'ಊಟ'],
      animationName: 'FOOD',
      assetPath: 'assets/sign_language/animations/food.glb',
    ),
    SignLanguagePhrase(
      id: 'medicine',
      displayText: 'Medicine',
      aliases: ['medicine', 'pills', 'medication', 'दवा', 'మందు', 'மருந்து', 'ಔಷಧಿ'],
      animationName: 'MEDICINE',
      assetPath: 'assets/sign_language/animations/medicine.glb',
    ),
    SignLanguagePhrase(
      id: 'hospital',
      displayText: 'Hospital',
      aliases: ['hospital', 'clinic', 'medical center', 'अस्पताल', 'ఆసుపత్రి', 'மருத்துவமனை', 'ಆಸ್ಪತ್ರೆ'],
      animationName: 'HOSPITAL',
      assetPath: 'assets/sign_language/animations/hospital.glb',
    ),
    SignLanguagePhrase(
      id: 'doctor',
      displayText: 'Doctor',
      aliases: ['doctor', 'dr', 'physician', 'डॉक्टर', 'డాక్టర్', 'டாக்டர்', 'ವೈದ್ಯರು'],
      animationName: 'DOCTOR',
      assetPath: 'assets/sign_language/animations/doctor.glb',
    ),
    SignLanguagePhrase(
      id: 'toilet',
      displayText: 'Toilet / Washroom',
      aliases: ['toilet', 'washroom', 'restroom', 'bathroom', 'शौचालय', 'మరుగుదొడ్డి', 'கழிப்பறை'],
      animationName: 'TOILET',
      assetPath: 'assets/sign_language/animations/toilet.glb',
    ),
    SignLanguagePhrase(
      id: 'come',
      displayText: 'Come',
      aliases: ['come', 'come here', 'आइए', 'రండి', 'வாருங்கள்', 'ಬನ್ನಿ'],
      animationName: 'COME',
      assetPath: 'assets/sign_language/animations/come.glb',
    ),
    SignLanguagePhrase(
      id: 'go',
      displayText: 'Go',
      aliases: ['go', 'go there', 'जाइए', 'వెళ్లండి', 'போங்கள்', 'ಹೋಗಿ'],
      animationName: 'GO',
      assetPath: 'assets/sign_language/animations/go.glb',
    ),
    SignLanguagePhrase(
      id: 'wait',
      displayText: 'Wait',
      aliases: ['wait', 'wait here', 'hold on', 'इंतजार करें', 'ఆగండి', 'காத்திருங்கள்'],
      animationName: 'WAIT',
      assetPath: 'assets/sign_language/animations/wait.glb',
    ),
    SignLanguagePhrase(
      id: 'i_understand',
      displayText: 'I understand',
      aliases: ['i understand', 'understood', 'i get it', 'समझ गया', 'నాకు అర్థమైంది'],
      animationName: 'I_UNDERSTAND',
      assetPath: 'assets/sign_language/animations/i_understand.glb',
    ),
    SignLanguagePhrase(
      id: 'i_dont_understand',
      displayText: "I don't understand",
      aliases: ["i don't understand", 'dont understand', 'not understood', 'नहीं समझा', 'అర్థం కాలేదు'],
      animationName: 'I_DONT_UNDERSTAND',
      assetPath: 'assets/sign_language/animations/i_dont_understand.glb',
    ),
    SignLanguagePhrase(
      id: 'what_are_you_doing',
      displayText: 'What are you doing?',
      aliases: ['what are you doing', 'what r u doing', 'what are u doing', 'आप क्या कर रहे हैं'],
      animationName: 'WHAT_ARE_YOU_DOING',
      assetPath: 'assets/sign_language/animations/what_are_you_doing.glb',
    ),
  ];

  /// Normalize input text for flexible phrase matching
  static String normalize(String rawInput) {
    return rawInput
        .toLowerCase()
        .replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Find matching ISL phrase entry from raw text input or query
  static SignLanguagePhrase? findPhrase(String rawInput) {
    final clean = normalize(rawInput);
    if (clean.isEmpty) return null;

    // 1. Exact phrase ID match
    for (final p in phrases) {
      if (p.id == clean || normalize(p.displayText) == clean) {
        return p;
      }
    }

    // 2. Alias exact match
    for (final p in phrases) {
      for (final alias in p.aliases) {
        if (normalize(alias) == clean) {
          return p;
        }
      }
    }

    // 3. Substring alias match
    for (final p in phrases) {
      for (final alias in p.aliases) {
        final cleanAlias = normalize(alias);
        if (cleanAlias.length >= 3 && (clean.contains(cleanAlias) || cleanAlias.contains(clean))) {
          return p;
        }
      }
    }

    return null;
  }
}
