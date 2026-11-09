import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../core/services/stt_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/registries/isl_video_registry.dart';
import '../widgets/isl_video_player_widget.dart';

/// Screen B — Text to Sign Language
/// Accepts typed or spoken text, maps words and phrases to genuine Indian Sign Language (ISL) demonstrations,
/// and plays verified high-definition sign videos in sequence with dedicated playback controls.
class TextToSignLanguagePage extends StatefulWidget {
  const TextToSignLanguagePage({super.key});

  @override
  State<TextToSignLanguagePage> createState() => _TextToSignLanguagePageState();
}

class _TextToSignLanguagePageState extends State<TextToSignLanguagePage> {
  final TextEditingController _textController = TextEditingController();
  final SttService _sttService = sl<SttService>();

  List<IslVideoClip> _playlist = [];
  int _currentClipIndex = 0;
  bool _isListening = false;
  String _enteredQuery = 'Hello';
  List<String> _unsupportedWords = [];

  static const List<String> quickPhrases = [
    'Hello',
    'Thank You',
    'Help',
    'Water',
    'Food',
    'Caregiver',
    'Emergency',
    'Clean',
    'Come',
    'Drink',
    'Hospital',
    'Doctor',
  ];

  @override
  void initState() {
    super.initState();
    _translateTextToSignSequence('Hello');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Translates full text or individual words into an ordered list of genuine ISL video clips.
  void _translateTextToSignSequence(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    setState(() {
      _enteredQuery = query;
      _unsupportedWords = [];
      _playlist = [];
      _currentClipIndex = 0;
    });

    // 1. Check if the entire multi-word query directly matches a known sign (e.g. "thank you", "good morning")
    final directMatch = IslVideoRegistry.findClip(query);
    if (directMatch != null) {
      setState(() {
        _playlist = [directMatch];
      });
      return;
    }

    // 2. Tokenize words and match available ISL signs
    final words = query
        .toLowerCase()
        .replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final List<IslVideoClip> matched = [];
    final List<String> missing = [];

    int i = 0;
    while (i < words.length) {
      // Check 2-word phrase combinations first (e.g. "thank you")
      if (i + 1 < words.length) {
        final twoWord = '${words[i]} ${words[i + 1]}';
        final clip = IslVideoRegistry.findClip(twoWord);
        if (clip != null) {
          matched.add(clip);
          i += 2;
          continue;
        }
      }

      // Check single word
      final singleClip = IslVideoRegistry.findClip(words[i]);
      if (singleClip != null) {
        matched.add(singleClip);
      } else {
        missing.add(words[i]);
      }
      i++;
    }

    setState(() {
      _playlist = matched;
      _unsupportedWords = missing;
      _currentClipIndex = 0;
    });
  }

  Future<void> _startVoiceInput() async {
    if (_isListening) {
      await _sttService.stopListening();
      setState(() {
        _isListening = false;
      });
      return;
    }

    final isAvailable = await _sttService.initialize();
    if (!mounted) return;
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is unavailable on this device.')),
      );
      return;
    }

    setState(() {
      _isListening = true;
    });

    await _sttService.startListening(
      onResult: (transcript, isFinal) {
        setState(() {
          _textController.text = transcript;
        });
        if (isFinal) {
          setState(() {
            _isListening = false;
          });
          _translateTextToSignSequence(transcript);
        }
      },
      onComplete: () {
        setState(() {
          _isListening = false;
        });
      },
    );
  }

  void _clearAll() {
    _textController.clear();
    setState(() {
      _enteredQuery = '';
      _playlist = [];
      _unsupportedWords = [];
      _currentClipIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IslVideoClip? activeClip =
        _playlist.isNotEmpty && _currentClipIndex < _playlist.length
            ? _playlist[_currentClipIndex]
            : null;

    return AccessibilityScaffold(
      pageTitle: 'Text to Sign Language',
      appBar: const CustomAppBar(
        title: 'Text to Sign Language',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AdiuvaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Text & Speech Input Card
              AdiuvaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Enter text to translate into sign language',
                            hintText: 'e.g. Hello, Thank You, Water, Food...',
                            controller: _textController,
                            onSubmitted: (val) => _translateTextToSignSequence(val),
                          ),
                        ),
                        const SizedBox(width: AdiuvaSpacing.sm),
                        IconButton.filled(
                          onPressed: _startVoiceInput,
                          icon: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: _isListening ? AdiuvaColors.primaryTeal : null,
                          ),
                          tooltip: 'Speak text',
                        ),
                        const SizedBox(width: AdiuvaSpacing.xs),
                        IconButton.filledTonal(
                          onPressed: () => _translateTextToSignSequence(_textController.text),
                          icon: const Icon(Icons.translate_rounded),
                          tooltip: 'Translate to Sign',
                        ),
                        const SizedBox(width: AdiuvaSpacing.xs),
                        IconButton.outlined(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: 'Clear input',
                        ),
                      ],
                    ),
                    AdiuvaSpacing.gapSm,

                    // Quick Phrase Suggestions
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: quickPhrases.map((phrase) {
                          final isSelected =
                              _enteredQuery.toLowerCase() == phrase.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(phrase),
                              backgroundColor: isSelected
                                  ? AdiuvaColors.primaryTeal.withValues(alpha: 0.25)
                                  : null,
                              side: BorderSide(
                                color: isSelected
                                    ? AdiuvaColors.primaryTeal
                                    : Colors.transparent,
                              ),
                              onPressed: () {
                                _textController.text = phrase;
                                _translateTextToSignSequence(phrase);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              AdiuvaSpacing.gapMd,

              // 2. Active User-Entered Query Display
              if (_enteredQuery.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AdiuvaColors.darkSurface : AdiuvaColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AdiuvaColors.darkBorder : AdiuvaColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.format_quote_rounded, color: AdiuvaColors.primaryTeal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _enteredQuery,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Feedback for Unavailable Signs
              if (_unsupportedWords.isNotEmpty) ...[
                AdiuvaSpacing.gapSm,
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sign demonstration unavailable for: ${_unsupportedWords.map((w) => '"$w"').join(', ')}. Tap any verified sign below to view its demonstration.',
                          style: TextStyle(
                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              AdiuvaSpacing.gapMd,

              // 3. Genuine Indian Sign Language Demonstration Video Player
              if (activeClip != null) ...[
                // Playlist step indicator if multi-sign sentence
                if (_playlist.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sign ${_currentClipIndex + 1} of ${_playlist.length}: ${activeClip.displayText}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdiuvaColors.primaryTeal,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            tooltip: 'Previous sign',
                            onPressed: _currentClipIndex > 0
                                ? () {
                                    setState(() {
                                      _currentClipIndex--;
                                    });
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            tooltip: 'Next sign',
                            onPressed: _currentClipIndex < _playlist.length - 1
                                ? () {
                                    setState(() {
                                      _currentClipIndex++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Video Demonstration Card
                IslVideoPlayerWidget(
                  key: ValueKey(activeClip.assetPath),
                  clip: activeClip,
                  onFinished: () {
                    if (_currentClipIndex < _playlist.length - 1) {
                      setState(() {
                        _currentClipIndex++;
                      });
                    }
                  },
                ),
              ] else if (_enteredQuery.isNotEmpty && _playlist.isEmpty) ...[
                // When query has no matching signs at all
                Container(
                  padding: const EdgeInsets.all(AdiuvaSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark ? AdiuvaColors.darkSurface : AdiuvaColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AdiuvaColors.darkBorder : AdiuvaColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.videocam_off_rounded, size: 48, color: Colors.grey),
                      AdiuvaSpacing.gapMd,
                      Text(
                        'No matching sign demonstration found for "$_enteredQuery".',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      AdiuvaSpacing.gapSm,
                      Text(
                        'Please choose from the 61 verified Indian Sign Language demonstrations below.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              AdiuvaSpacing.gapLg,

              // 4. Directory of 61 Supported Signs
              Text(
                'Available Indian Sign Language Demonstrations (${IslVideoRegistry.clips.length} Signs)',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              AdiuvaSpacing.gapXs,
              Text(
                'Tap any word to view its human sign-language demonstration video:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AdiuvaSpacing.gapSm,

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: IslVideoRegistry.clips.map((clip) {
                  final isCurrent = activeClip?.category == clip.category;
                  return ChoiceChip(
                    label: Text(clip.displayText),
                    selected: isCurrent,
                    selectedColor: AdiuvaColors.primaryTeal.withValues(alpha: 0.3),
                    onSelected: (selected) {
                      if (selected) {
                        _textController.text = clip.displayText;
                        _translateTextToSignSequence(clip.displayText);
                      }
                    },
                  );
                }).toList(),
              ),

              AdiuvaSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }
}
