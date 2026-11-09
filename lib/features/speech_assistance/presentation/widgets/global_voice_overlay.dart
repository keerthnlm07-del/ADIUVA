import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/global_voice_control_provider.dart';

/// Small, compact global live transcript & status indicator widget.
/// Automatically host-rendered across all app screens via _GlobalVoiceHost.
class GlobalVoiceOverlay extends StatelessWidget {
  const GlobalVoiceOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalVoiceControlProvider>(
      builder: (context, provider, child) {
        // Do not render overlay on unauthenticated initial splash or if voice is disabled
        if (!provider.isAutoVoiceEnabled && provider.state == GlobalVoiceState.stopped) {
          return const SizedBox.shrink();
        }

        final state = provider.state;
        final String displayText = provider.displayTranscript;

        Color badgeColor;
        String stateLabel;
        IconData stateIcon;

        switch (state) {
          case GlobalVoiceState.listening:
            badgeColor = const Color(0xFF00E676); // Vibrant Green
            stateLabel = 'LISTENING';
            stateIcon = Icons.mic;
            break;
          case GlobalVoiceState.processingCommand:
            badgeColor = const Color(0xFFFF9100); // Amber Orange
            stateLabel = 'PROCESSING';
            stateIcon = Icons.sync;
            break;
          case GlobalVoiceState.speaking:
            badgeColor = const Color(0xFFD500F9); // Purple
            stateLabel = 'SPEAKING';
            stateIcon = Icons.volume_up;
            break;
          case GlobalVoiceState.yieldedToFeature:
            badgeColor = const Color(0xFF2979FF); // Blue
            stateLabel = 'PAUSED';
            stateIcon = Icons.pause;
            break;
          case GlobalVoiceState.error:
            badgeColor = const Color(0xFFFF1744); // Bright Red
            stateLabel = 'ERROR';
            stateIcon = Icons.error_outline;
            break;
          case GlobalVoiceState.stopped:
            badgeColor = const Color(0xFF9E9E9E); // Grey
            stateLabel = 'STOPPED';
            stateIcon = Icons.mic_off;
            break;
          case GlobalVoiceState.idle:
            badgeColor = const Color(0xFF00E676);
            stateLabel = 'LISTENING';
            stateIcon = Icons.mic;
            break;
        }

        return IgnorePointer(
          ignoring: true, // Non-blocking overlay touch pass-through
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xEC121824), // Dark translucent pill
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      stateIcon,
                      size: 14,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stateLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 12,
                      width: 1,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        displayText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
