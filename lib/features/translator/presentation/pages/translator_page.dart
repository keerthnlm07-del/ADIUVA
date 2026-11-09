import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/stt_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/di/service_locator.dart';


/// Free-Form Speech & Text Translator Page
/// Powered by Google ML Kit On-Device Translation with Firebase AI (Gemini) Fallback
class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final TextEditingController _inputController = TextEditingController();
  final SttService _sttService = sl<SttService>();
  final TtsService _ttsService = sl<TtsService>();

  String _sourceLanguage = 'Auto-Detect';
  String _targetLanguage = 'Telugu';
  String _translatedResult = '';
  bool _isTranslating = false;
  String? _statusMessage;
  bool _isListening = false;
  String? _errorMessage;

  static const List<String> _sourceLanguages = [
    'Auto-Detect',
    'English',
    'Hindi',
    'Telugu',
    'Tamil',
    'Kannada',
    'Spanish',
    'French',
    'German',
  ];

  static const List<String> _targetLanguages = [
    'English',
    'Telugu',
    'Tamil',
    'Kannada',
    'Hindi',
    'Spanish',
    'French',
    'German',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _swapLanguages() {
    if (_sourceLanguage == 'Auto-Detect') {
      setState(() {
        _sourceLanguage = _targetLanguage;
        _targetLanguage = 'English';
      });
    } else {
      setState(() {
        final temp = _sourceLanguage;
        _sourceLanguage = _targetLanguage;
        _targetLanguage = temp;
      });
    }
  }

  Future<void> _startSpeechToTextInput() async {
    if (_isListening) {
      await _sttService.stopListening();
      setState(() {
        _isListening = false;
      });
      return;
    }

    final isAvailable = await _sttService.initialize();
    if (!isAvailable) {
      setState(() {
        _errorMessage = 'Speech recognition unavailable';
      });
      return;
    }

    setState(() {
      _isListening = true;
      _errorMessage = null;
    });

    String localeId = 'en-IN';
    if (_sourceLanguage == 'Hindi') localeId = 'hi-IN';
    if (_sourceLanguage == 'Telugu') localeId = 'te-IN';
    if (_sourceLanguage == 'Tamil') localeId = 'ta-IN';
    if (_sourceLanguage == 'Kannada') localeId = 'kn-IN';

    await _sttService.startListening(
      localeId: localeId,
      onResult: (transcript, isFinal) {
        setState(() {
          _inputController.text = transcript;
        });
        if (isFinal) {
          setState(() {
            _isListening = false;
          });
        }
      },
      onComplete: () {
        setState(() {
          _isListening = false;
        });
      },
    );
  }

  static const Map<String, String> _languageCodeMap = {
    'Auto-Detect': 'auto',
    'English': 'en',
    'Hindi': 'hi',
    'Telugu': 'te',
    'Tamil': 'ta',
    'Kannada': 'kn',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
  };

  /// Lightweight Online Translation with graceful fallback
  Future<String?> _translateOnline(String text, String srcLang, String tgtLang) async {
    final srcCode = _languageCodeMap[srcLang] ?? 'auto';
    final tgtCode = _languageCodeMap[tgtLang] ?? 'en';
    final pair = '$srcCode|$tgtCode';

    // 1. Primary: Lightweight, fast online translation service (MyMemory API)
    HttpClient? client;
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$pair',
      );
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Adiuva/1.0 (Android)');
      final response = await request.close().timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;

        // Inspect high-quality matches first
        if (data.containsKey('matches') && data['matches'] is List) {
          final matches = data['matches'] as List;
          for (final m in matches) {
            if (m is Map && m['translation'] != null) {
              final t = m['translation'].toString().trim();
              if (t.isNotEmpty && !t.startsWith('MYMEMORY WARNING')) {
                return t;
              }
            }
          }
        }

        final resData = data['responseData'];
        if (resData != null && resData is Map && resData['translatedText'] != null) {
          final t = resData['translatedText'].toString().trim();
          if (t.isNotEmpty && !t.startsWith('MYMEMORY WARNING')) {
            return t;
          }
        }
      }
    } catch (e) {
      debugPrint('[TRANSLATOR] Online service note: $e. Falling back to Firebase AI...');
    } finally {
      client?.close();
    }

    // 2. Secondary: Firebase AI (Gemini) Translation Fallback
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
      );
      final prompt =
          'You are a professional translator. Translate the following text from $srcLang to $tgtLang. Provide ONLY the direct translation result, without any intro, metadata, quotes, or commentary:\n\n"$text"';

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 5));

      final result = response.text?.trim() ?? '';
      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      debugPrint('[TRANSLATOR] Firebase AI fallback error: $e');
    }

    return null;
  }

  Future<void> _performTranslation() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter or speak text to translate.';
      });
      return;
    }

    if (_sourceLanguage.toLowerCase() == _targetLanguage.toLowerCase() &&
        _sourceLanguage != 'Auto-Detect') {
      setState(() {
        _translatedResult = text;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
      _statusMessage = 'Translating online...';
      _errorMessage = null;
      _translatedResult = '';
    });

    try {
      final translated = await _translateOnline(text, _sourceLanguage, _targetLanguage);

      if (!mounted) return;

      if (translated != null && translated.isNotEmpty) {
        setState(() {
          _translatedResult = translated;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Translation failed. Please check your internet connection and try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Translation error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _statusMessage = null;
        });
      }
    }
  }


  Future<void> _readResultAloud() async {
    if (_translatedResult.isEmpty) return;
    String locale = 'en-IN';
    if (_targetLanguage == 'Hindi') locale = 'hi-IN';
    if (_targetLanguage == 'Telugu') locale = 'te-IN';
    if (_targetLanguage == 'Tamil') locale = 'ta-IN';
    if (_targetLanguage == 'Kannada') locale = 'kn-IN';

    await _ttsService.setLanguage(locale);
    await _ttsService.speak(_translatedResult);
  }

  void _copyResultToClipboard() {
    if (_translatedResult.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _translatedResult));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AccessibilityScaffold(
      pageTitle: 'Translator',
      appBar: const CustomAppBar(
        title: 'Free-Form Translator',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdiuvaSpacing.gapLg,

            // Language Selector Row
            AdiuvaCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DropdownButton<String>(
                              isExpanded: true,
                              value: _sourceLanguage,
                              underline: Container(height: 1, color: theme.colorScheme.primary),
                              items: _sourceLanguages.map((lang) {
                                return DropdownMenuItem(
                                  value: lang,
                                  child: Text(lang, style: theme.textTheme.titleMedium),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _sourceLanguage = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz_rounded, size: 28),
                        color: theme.colorScheme.primary,
                        tooltip: 'Swap Languages',
                        onPressed: _swapLanguages,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DropdownButton<String>(
                              isExpanded: true,
                              value: _targetLanguage,
                              underline: Container(height: 1, color: theme.colorScheme.primary),
                              items: _targetLanguages.map((lang) {
                                return DropdownMenuItem(
                                  value: lang,
                                  child: Text(lang, style: theme.textTheme.titleMedium),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _targetLanguage = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapLg,

            // Text Input Card
            AdiuvaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Text to Translate',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          if (_inputController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              tooltip: 'Clear input',
                              onPressed: () {
                                setState(() {
                                  _inputController.clear();
                                  _translatedResult = '';
                                  _errorMessage = null;
                                });
                              },
                            ),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                              color: _isListening ? AdiuvaColors.error : theme.colorScheme.primary,
                            ),
                            tooltip: _isListening ? 'Listening...' : 'Speak input',
                            onPressed: _startSpeechToTextInput,
                          ),
                        ],
                      ),
                    ],
                  ),
                  AdiuvaSpacing.gapSm,
                  TextField(
                    controller: _inputController,
                    minLines: 4,
                    maxLines: 8,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Enter or speak any word, sentence, or paragraph...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  AdiuvaSpacing.gapMd,
                  CustomButton.primary(
                    label: _isTranslating ? (_statusMessage ?? 'Translating...') : 'Translate',
                    leadingIcon: Icons.translate_rounded,
                    onPressed: _isTranslating ? null : _performTranslation,
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapLg,

            // Error Display if any
            if (_errorMessage != null) ...[
              AdiuvaCard(
                backgroundColor: AdiuvaColors.error.withValues(alpha: 0.1),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyLarge?.copyWith(color: AdiuvaColors.error),
                ),
              ),
              AdiuvaSpacing.gapLg,
            ],

            // Translated Result Card
            if (_translatedResult.isNotEmpty || _isTranslating) ...[
              AdiuvaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Translation ($_targetLanguage)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (!_isTranslating)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded),
                                tooltip: 'Read Aloud',
                                onPressed: _readResultAloud,
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded),
                                tooltip: 'Copy Translation',
                                onPressed: _copyResultToClipboard,
                              ),
                            ],
                          ),
                      ],
                    ),
                    AdiuvaSpacing.gapSm,
                    if (_isTranslating)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              if (_statusMessage != null) ...[
                                AdiuvaSpacing.gapSm,
                                Text(
                                  _statusMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      SelectableText(
                        _translatedResult,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
              AdiuvaSpacing.gapXxl,
            ],
          ],
        ),
      ),
    );
  }
}
