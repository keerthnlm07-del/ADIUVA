import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../data/registries/isl_video_registry.dart';

/// Embedded Video Player for Indian Sign Language Human Demonstrations
class IslVideoPlayerWidget extends StatefulWidget {
  final IslVideoClip clip;
  final VoidCallback? onFinished;

  const IslVideoPlayerWidget({
    super.key,
    required this.clip,
    this.onFinished,
  });

  @override
  State<IslVideoPlayerWidget> createState() => _IslVideoPlayerWidgetState();
}

class _IslVideoPlayerWidgetState extends State<IslVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant IslVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.assetPath != widget.clip.assetPath) {
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    _controller?.dispose();
    _controller = null;
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final controller = VideoPlayerController.asset(widget.clip.assetPath);
      _controller = controller;

      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(true);
      await controller.play();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('[ISL_VIDEO] Video loading error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not load video clip for "${widget.clip.displayText}".';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Indian Sign Language human video demonstration for ${widget.clip.displayText}',
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AdiuvaColors.darkSurface : AdiuvaColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AdiuvaColors.darkBorder : AdiuvaColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Viewport
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isInitialized && _controller != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_controller!.value.isPlaying) {
                            _controller!.pause();
                          } else {
                            _controller!.play();
                          }
                        });
                      },
                      child: VideoPlayer(_controller!),
                    )
                  else if (_hasError)
                    Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.all(AdiuvaSpacing.md),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.orangeAccent, size: 36),
                            AdiuvaSpacing.gapSm,
                            Text(
                              _errorMessage ?? 'Video playback error',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            AdiuvaSpacing.gapSm,
                            FilledButton.tonal(
                              onPressed: _initPlayer,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black87,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AdiuvaColors.primaryTeal,
                        ),
                      ),
                    ),

                  // Overlay Play/Pause indicator
                  if (_isInitialized && _controller != null && !_controller!.value.isPlaying)
                    Container(
                      color: Colors.black38,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Top info badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_rounded, size: 14, color: Colors.white),
                          AdiuvaSpacing.gapXs,
                          Text(
                            widget.clip.tag,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controls & Details Bar
            Padding(
              padding: const EdgeInsets.all(AdiuvaSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clip.displayText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AdiuvaColors.primaryTeal,
                          ),
                        ),
                        Text(
                          'Indian Sign Language Demonstration',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_isInitialized && _controller != null) ...[
                    IconButton.filledTonal(
                      icon: Icon(
                        _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      ),
                      tooltip: _controller!.value.isPlaying ? 'Pause' : 'Play',
                      onPressed: () {
                        setState(() {
                          if (_controller!.value.isPlaying) {
                            _controller!.pause();
                          } else {
                            _controller!.play();
                          }
                        });
                      },
                    ),
                    AdiuvaSpacing.gapXs,
                    IconButton.filledTonal(
                      icon: const Icon(Icons.replay_rounded),
                      tooltip: 'Replay from start',
                      onPressed: () {
                        _controller!.seekTo(Duration.zero);
                        _controller!.play();
                        setState(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
