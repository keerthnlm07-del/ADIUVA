import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/theme/adiuva_radius.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../config/routes/app_routes.dart';
import '../../domain/entities/chat_message.dart';
import '../provider/speech_assistance_provider.dart';

/// ADIUVA AI Assistant Screen
/// 
/// Features:
/// - Conversation history UI (User & Gemini AI messages)
/// - Quick prompt suggestion chips (56dp min hit targets)
/// - Text composer with send & voice entry buttons
/// - Loading / thinking state indicators
/// - Read aloud action via TtsService
/// - Copy to clipboard action with accessible announcement
/// - Retry action for failed Gemini requests
/// - Accessible empty and error states
class SpeechAssistancePage extends StatefulWidget {
  const SpeechAssistancePage({super.key});

  @override
  State<SpeechAssistancePage> createState() => _SpeechAssistancePageState();
}

class _SpeechAssistancePageState extends State<SpeechAssistancePage> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();

  static const List<String> _quickPrompts = [
    'What accessibility tools are available?',
    'Help me read text aloud',
    'Describe my surroundings',
    'How do I activate voice mode?',
  ];

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(SpeechAssistanceProvider provider, [String? customText]) {
    final text = customText ?? _composerController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _composerController.clear();
    }

    AccessibilityScaffold.announce('Sending prompt: $text');
    provider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<SpeechAssistanceProvider>(context);
    final messages = provider.messages;
    final isLoading = provider.isLoading;

    return AccessibilityScaffold(
      pageTitle: 'AI Assistant Screen',
      appBar: AppBar(
        title: Text(
          'ADIUVA Assistant',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (messages.isNotEmpty)
            Semantics(
              label: 'Clear conversation history',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () {
                  provider.clearHistory();
                  AccessibilityScaffold.announce('Conversation history cleared.');
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Conversation History or Empty State
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context, provider)
                : _buildMessageList(context, provider, messages),
          ),

          // Composer Input Bar
          _buildComposer(context, provider, isLoading),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SpeechAssistanceProvider provider) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AdiuvaSpacing.paddingLg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AdiuvaSpacing.gapLg,
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: AdiuvaColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 48,
              color: AdiuvaColors.primaryTeal,
            ),
          ),
          AdiuvaSpacing.gapLg,
          Text(
            'How can I help you today?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          AdiuvaSpacing.gapSm,
          Text(
            'Ask questions, summarize text, or request assistance using voice or text.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          AdiuvaSpacing.gapXxl,

          // Quick Prompt Chips Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Prompts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AdiuvaSpacing.gapMd,
          Column(
            children: _quickPrompts.map((prompt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AdiuvaSpacing.md),
                child: CustomButton.outlined(
                  label: prompt,
                  leadingIcon: Icons.chat_bubble_outline_rounded,
                  onPressed: () => _handleSend(provider, prompt),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    SpeechAssistanceProvider provider,
    List<ChatMessage> messages,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: AdiuvaSpacing.paddingLg,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageItem(context, provider, message);
      },
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    SpeechAssistanceProvider provider,
    ChatMessage message,
  ) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: AdiuvaSpacing.md),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AdiuvaColors.primaryContainer,
                  child: Icon(Icons.auto_awesome, size: 18, color: AdiuvaColors.primaryTeal),
                ),
                const SizedBox(width: AdiuvaSpacing.sm),
              ],
              Text(
                isUser ? 'You' : 'ADIUVA Assistant',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: AdiuvaSpacing.sm),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AdiuvaColors.slate200,
                  child: Icon(Icons.person, size: 18, color: AdiuvaColors.slate800),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            child: AdiuvaCard(
              backgroundColor: message.isError
                  ? theme.colorScheme.errorContainer
                  : (isUser
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surface),
              elevation: isUser ? 0 : 1,
              padding: AdiuvaSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isStreaming) ...[
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                        const SizedBox(width: AdiuvaSpacing.md),
                        Text(
                          message.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      message.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: message.isError
                            ? theme.colorScheme.onErrorContainer
                            : (isUser
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface),
                      ),
                    ),
                  ],

                  // Action Buttons for Assistant Responses (TTS & Copy & Retry)
                  if (!isUser && !message.isStreaming) ...[
                    AdiuvaSpacing.gapSm,
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (message.isError)
                          Semantics(
                            label: 'Retry failed request',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: AdiuvaColors.error),
                              onPressed: () {
                                AccessibilityScaffold.announce('Retrying last prompt.');
                                provider.retryLastPrompt();
                              },
                            ),
                          )
                        else ...[
                          // Read Aloud Action Button
                          Semantics(
                            label: 'Read response aloud',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.volume_up_outlined),
                              onPressed: () {
                                AccessibilityScaffold.announce('Reading response aloud.');
                                provider.speakMessage(message.text);
                              },
                            ),
                          ),
                          // Copy Action Button
                          Semantics(
                            label: 'Copy response to clipboard',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.copy_outlined),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: message.text));
                                AccessibilityScaffold.announce('Response copied to clipboard.');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Response copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    SpeechAssistanceProvider provider,
    bool isLoading,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdiuvaSpacing.lg,
        vertical: AdiuvaSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Entry Button (Sand/Amber styling)
            Semantics(
              label: 'Voice Assistant Action',
              hint: 'Double tap to activate voice mode screen',
              button: true,
              child: Container(
                width: AdiuvaSpacing.minTouchTarget,
                height: AdiuvaSpacing.minTouchTarget,
                decoration: const BoxDecoration(
                  color: AdiuvaColors.voiceAmber,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic_none_rounded, color: AdiuvaColors.onVoiceContainer),
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.voiceMode);
                  },
                ),
              ),
            ),
            const SizedBox(width: AdiuvaSpacing.md),

            // Text Input Field
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AdiuvaSpacing.minTouchTarget,
                ),
                child: TextField(
                  controller: _composerController,
                  focusNode: _composerFocusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(provider),
                  decoration: InputDecoration(
                    hintText: 'Ask ADIUVA anything...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AdiuvaSpacing.lg,
                      vertical: AdiuvaSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AdiuvaRadius.borderRadiusPill,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AdiuvaSpacing.md),

            // Send Button (56dp min hit area)
            Semantics(
              label: 'Send message',
              button: true,
              child: SizedBox(
                width: AdiuvaSpacing.minTouchTarget,
                height: AdiuvaSpacing.minTouchTarget,
                child: IconButton.filled(
                  onPressed: isLoading ? null : () => _handleSend(provider),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
