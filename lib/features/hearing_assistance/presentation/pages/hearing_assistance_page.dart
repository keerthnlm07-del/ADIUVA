import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/stt_service.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../core/widgets/adiuva_icon_tile.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../speech_assistance/presentation/provider/global_voice_control_provider.dart';

/// ADIUVA Hearing Assistance Dashboard — Icon-First Design
class HearingAssistancePage extends StatefulWidget {
  const HearingAssistancePage({super.key});

  @override
  State<HearingAssistancePage> createState() => _HearingAssistancePageState();
}

class _HearingAssistancePageState extends State<HearingAssistancePage> {
  final SttService _sttService = sl<SttService>();
  bool _isLiveCaptioning = false;
  String _liveCaptions = '';

  final List<Map<String, dynamic>> _soundAlerts = [
    {
      'label': 'Doorbell Alert',
      'time': 'Active',
      'icon': Icons.doorbell_rounded,
      'color': AdiuvaColors.primaryTeal,
    },
    {
      'label': 'Fire Alarm',
      'time': 'Monitored',
      'icon': Icons.local_fire_department_rounded,
      'color': AdiuvaColors.error,
    },
    {
      'label': 'Vehicle Honk',
      'time': 'Monitored',
      'icon': Icons.volume_up_rounded,
      'color': AdiuvaColors.voiceAmber,
    },
  ];

  @override
  void dispose() {
    _stopCaptioning();
    super.dispose();
  }

  Future<void> _startCaptioning() async {
    final globalVoice = Provider.of<GlobalVoiceControlProvider>(context, listen: false);
    await globalVoice.yieldMicrophoneToFeature(true);

    setState(() {
      _isLiveCaptioning = true;
      _liveCaptions = 'Listening to speech...';
    });

    await _sttService.startListening(
      onResult: (text) {
        if (mounted && text.isNotEmpty) {
          setState(() {
            _liveCaptions = text;
          });
        }
      },
      onComplete: () {
        if (mounted && _isLiveCaptioning) {
          _startCaptioning();
        }
      },
    );
  }

  Future<void> _stopCaptioning() async {
    _isLiveCaptioning = false;
    await _sttService.stopListening();
    final rootCtx = AppRoutes.navigatorKey.currentContext;
    if (rootCtx != null && rootCtx.mounted) {
      try {
        await Provider.of<GlobalVoiceControlProvider>(rootCtx, listen: false)
            .yieldMicrophoneToFeature(false);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleCaptioning() async {
    if (_isLiveCaptioning) {
      await _stopCaptioning();
      AccessibilityScaffold.announce('Live captioning stopped.');
    } else {
      await _startCaptioning();
      AccessibilityScaffold.announce('Live captioning started.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> hearingTools = [
      {
        'title': 'Live Captions',
        'icon': Icons.subtitles_rounded,
        'color': AdiuvaColors.primaryTeal,
        'action': _toggleCaptioning,
      },
      {
        'title': 'Sign Language',
        'icon': Icons.sign_language_rounded,
        'color': Colors.purple,
        'action': () => Navigator.of(context).pushNamed(AppRoutes.signLanguage),
      },
      {
        'title': 'Translator',
        'icon': Icons.translate_rounded,
        'color': Colors.blue,
        'action': () => Navigator.of(context).pushNamed(AppRoutes.translator),
      },
    ];

    return AccessibilityScaffold(
      pageTitle: 'Hearing Assistance',
      appBar: CustomAppBar(
        title: 'Hearing Helper',
        showBackButton: true,
        onBackPressed: () async {
          final navigator = Navigator.of(context);
          await _stopCaptioning();
          navigator.pop();
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdiuvaSpacing.gapLg,

            // Live Captioning Toggle Button
            CustomButton.primary(
              label: _isLiveCaptioning ? 'Stop Live Captions' : 'Start Live Captions',
              leadingIcon: _isLiveCaptioning ? Icons.mic_off_rounded : Icons.mic_rounded,
              onPressed: _toggleCaptioning,
            ),
            AdiuvaSpacing.gapMd,

            // Live Caption Display Card
            AdiuvaCard(
              padding: AdiuvaSpacing.paddingMd,
              backgroundColor: _isLiveCaptioning
                  ? AdiuvaColors.voiceContainer.withValues(alpha: 0.3)
                  : theme.colorScheme.surfaceContainerHighest,
              child: SelectableText(
                _liveCaptions.isEmpty ? 'Tap "Start Live Captions" to transcribe speech.' : _liveCaptions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            AdiuvaSpacing.gapLg,

            // Icon-First 2-Column Grid for Hearing Tools
            Text(
              'Hearing Tools',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AdiuvaSpacing.gapSm,
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hearingTools.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AdiuvaSpacing.md,
                mainAxisSpacing: AdiuvaSpacing.md,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final tool = hearingTools[index];
                return AdiuvaIconTile(
                  title: tool['title'] as String,
                  icon: tool['icon'] as IconData,
                  color: tool['color'] as Color,
                  onTap: tool['action'] as VoidCallback,
                );
              },
            ),
            AdiuvaSpacing.gapLg,

            // Environmental Sound Alerts (Compact Visual Indicators)
            Text(
              'Visual Sound Alerts',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AdiuvaSpacing.gapSm,
            Row(
              children: _soundAlerts.map((alert) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: AdiuvaCard(
                      padding: const EdgeInsets.all(AdiuvaSpacing.sm),
                      child: Column(
                        children: [
                          Icon(alert['icon'] as IconData, color: alert['color'] as Color, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            alert['label'] as String,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            AdiuvaSpacing.gapLg,

            // SOS Shortcut
            AdiuvaIconTile(
              title: 'Emergency SOS',
              subtitle: 'Instant emergency alert',
              icon: Icons.sos_rounded,
              color: AdiuvaColors.error,
              semanticLabel: 'Open Emergency SOS',
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.emergencySos);
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
