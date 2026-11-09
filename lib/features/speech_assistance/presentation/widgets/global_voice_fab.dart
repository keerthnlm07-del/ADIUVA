import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../provider/global_voice_control_provider.dart';

/// ADIUVA Global Voice Control FAB Widget
/// 
/// Compulsory visual microphone fallback control rendered across all screens.
/// Displays real-time voice engine states:
/// - LISTENING
/// - PROCESSING
/// - SPEAKING
/// - PAUSED / FEATURE MICROPHONE ACTIVE
/// - ERROR / RETRY
class GlobalVoiceFab extends StatelessWidget {
  const GlobalVoiceFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalVoiceControlProvider>(
      builder: (context, voiceProvider, child) {
        final state = voiceProvider.state;
        final isYielded = voiceProvider.isYieldedToFeature;

        IconData icon;
        Color color;
        String label;

        if (isYielded || state == GlobalVoiceState.yieldedToFeature) {
          icon = Icons.mic_off_rounded;
          color = AdiuvaColors.slate500;
          label = 'Microphone currently in use by this feature';
        } else {
          switch (state) {
            case GlobalVoiceState.listening:
              icon = Icons.graphic_eq_rounded;
              color = AdiuvaColors.voiceAmber;
              label = 'Listening... Speak now';
              break;
            case GlobalVoiceState.processingCommand:
              icon = Icons.auto_awesome_rounded;
              color = AdiuvaColors.primaryTeal;
              label = 'Processing command...';
              break;
            case GlobalVoiceState.speaking:
              icon = Icons.volume_up_rounded;
              color = AdiuvaColors.voiceAmberDark;
              label = 'Speaking response...';
              break;
            case GlobalVoiceState.error:
              icon = Icons.warning_amber_rounded;
              color = Colors.red;
              label = 'Voice error. Tap to retry';
              break;
            case GlobalVoiceState.stopped:
            case GlobalVoiceState.idle:
            default:
              icon = Icons.mic_rounded;
              color = AdiuvaColors.primaryTeal;
              label = 'Voice active. Tap for manual control';
              break;
          }
        }

        return Tooltip(
          message: label,
          child: FloatingActionButton(
            heroTag: 'global_voice_fab_${context.widget.hashCode}',
            backgroundColor: color,
            foregroundColor: Colors.white,
            onPressed: () {
              if (isYielded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Microphone is currently in use by this feature.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (state == GlobalVoiceState.speaking) {
                voiceProvider.stopSession();
              } else {
                voiceProvider.startManualSession(context);
              }
            },
            child: state == GlobalVoiceState.processingCommand
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(icon, size: 28),
          ),
        );
      },
    );
  }
}
