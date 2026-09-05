import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_motion.dart';
import '../provider/voice_mode_provider.dart';

/// Signature 96dp ADIUVA Voice Mode Control Button with Pulsing Waveform
class VoiceButtonWidget extends StatefulWidget {
  final VoiceStateEnum state;
  final VoidCallback onTap;

  const VoiceButtonWidget({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  State<VoiceButtonWidget> createState() => _VoiceButtonWidgetState();
}

class _VoiceButtonWidgetState extends State<VoiceButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AdiuvaMotion.durationPulse,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AdiuvaMotion.curvePulse,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant VoiceButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (widget.state == VoiceStateEnum.listening && !disableAnimations) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.state) {
      case VoiceStateEnum.idle:
        return Icons.mic_rounded;
      case VoiceStateEnum.listening:
        return Icons.graphic_eq_rounded;
      case VoiceStateEnum.processing:
        return Icons.auto_awesome_rounded;
      case VoiceStateEnum.speaking:
        return Icons.volume_up_rounded;
      case VoiceStateEnum.paused:
        return Icons.pause_rounded;
      case VoiceStateEnum.error:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.state) {
      case VoiceStateEnum.idle:
      case VoiceStateEnum.listening:
        return AdiuvaColors.voiceAmber;
      case VoiceStateEnum.processing:
        return AdiuvaColors.primaryTeal;
      case VoiceStateEnum.speaking:
        return AdiuvaColors.voiceAmberDark;
      case VoiceStateEnum.paused:
        return AdiuvaColors.slate500;
      case VoiceStateEnum.error:
        return AdiuvaColors.error;
    }
  }

  String _getSemanticLabel() {
    switch (widget.state) {
      case VoiceStateEnum.idle:
        return 'Voice Assistant button. Double tap to start speaking.';
      case VoiceStateEnum.listening:
        return 'Listening to your speech. Double tap to stop.';
      case VoiceStateEnum.processing:
        return 'Gemini AI is processing your speech.';
      case VoiceStateEnum.speaking:
        return 'Assistant is speaking response. Double tap to stop speech (barge in).';
      case VoiceStateEnum.paused:
        return 'Voice mode paused. Double tap to resume.';
      case VoiceStateEnum.error:
        return 'Error occurred. Double tap to retry.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.state == VoiceStateEnum.listening;

    return Semantics(
      button: true,
      label: _getSemanticLabel(),
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            final scale = isListening ? _scaleAnimation.value : 1.0;

            return SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Pulsing Ring
                  if (isListening)
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AdiuvaColors.voiceAmber.withValues(alpha: 0.25),
                        ),
                      ),
                    ),

                  // 96dp Primary Control Button
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: FloatingActionButton(
                      heroTag: 'signature_voice_mode_button',
                      onPressed: widget.onTap,
                      backgroundColor: _getBackgroundColor(),
                      elevation: 8,
                      shape: const CircleBorder(),
                      child: widget.state == VoiceStateEnum.processing
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3.5,
                            )
                          : Icon(
                              _getIcon(),
                              size: 48,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
