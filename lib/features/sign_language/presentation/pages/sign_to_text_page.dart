import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/datasources/isl_tflite_service.dart';
import '../../../speech_assistance/presentation/provider/global_voice_control_provider.dart';

/// Explicit Sign Recognition State Machine
enum SignRecognitionState {
  ready,
  recording,
  analyzing,
  recognized,
  couldNotRecognize,
  handsNotDetected,
  permissionDenied,
  error,
}

/// Screen A — Sign Language to Text
/// Captures human signing from the camera or selected original video files,
/// extracts pose landmarks via ML Kit, and runs real on-device ISL neural network
/// inference (isl_model.tflite) to convert signs into readable text and speech.
class SignLanguageToTextPage extends StatefulWidget {
  const SignLanguageToTextPage({super.key});

  @override
  State<SignLanguageToTextPage> createState() => _SignLanguageToTextPageState();
}

class _SignLanguageToTextPageState extends State<SignLanguageToTextPage> with WidgetsBindingObserver {
  final CameraService _cameraService = sl<CameraService>();
  final TtsService _ttsService = sl<TtsService>();
  final IslTfliteService _islService = IslTfliteService();

  SignRecognitionState _state = SignRecognitionState.ready;
  bool _isCameraInitialized = false;
  bool _autoSpeakEnabled = true;

  String? _recognizedSign;
  double _recognitionConfidence = 0.0;
  String _statusText = 'Ready';
  String? _feedbackDetail;

  // Recording State & Frame Buffer
  Timer? _recordingTimer;
  int _recordingMilliseconds = 0;
  int _recordingDurationSeconds = 5; // Configurable duration: 3s, 5s, 7s
  int get _maxRecordingMs => _recordingDurationSeconds * 1000;
  final List<InputImage> _capturedFrames = [];
  DateTime? _lastSampledTime;

  static const List<String> supportedSigns = [
    'A',
    'B',
    'C',
    'D',
    'hello',
    'good_morning',
  ];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _islService.confidenceThreshold = 0.50; // Optimized for mobile motion variance
    _initPipeline();
  }

  Future<void> _initPipeline() async {
    setState(() {
      _statusText = 'Initializing...';
    });

    final modelLoaded = await _islService.initializeModel();
    debugPrint('[SIGN_TO_TEXT] ISL TFLite model loaded: $modelLoaded');

    // Default to front camera for selfie signing with YUV420 on Android
    await _cameraService.initializeCamera(
      CameraLensDirection.front,
      defaultTargetPlatform == TargetPlatform.android ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    if (!mounted) return;

    if (_cameraService.state == CameraState.ready) {
      setState(() {
        _isCameraInitialized = true;
        _state = SignRecognitionState.ready;
        _statusText = 'Ready';
      });
    } else if (_cameraService.state == CameraState.permissionDenied) {
      setState(() {
        _isCameraInitialized = false;
        _state = SignRecognitionState.permissionDenied;
        _statusText = 'Camera permission required';
      });
    } else {
      setState(() {
        _isCameraInitialized = false;
        _state = SignRecognitionState.error;
        _statusText = 'Camera error';
      });
    }
  }

  void _pauseGlobalVoice() {
    try {
      final voiceProvider = Provider.of<GlobalVoiceControlProvider>(context, listen: false);
      voiceProvider.yieldMicrophoneToFeature(true);
      debugPrint('[SIGN_TO_TEXT] Suspended global voice control during sign recognition');
    } catch (e) {
      debugPrint('[SIGN_TO_TEXT] Global voice pause note: $e');
    }
  }

  void _resumeGlobalVoice() {
    try {
      final voiceProvider = Provider.of<GlobalVoiceControlProvider>(context, listen: false);
      voiceProvider.yieldMicrophoneToFeature(false);
      debugPrint('[SIGN_TO_TEXT] Resumed global voice control after sign recognition');
    } catch (e) {
      debugPrint('[SIGN_TO_TEXT] Global voice resume note: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_state == SignRecognitionState.recording) {
      await _stopRecording(analyze: false);
    }
    await _cameraService.switchCamera();
    if (mounted) {
      setState(() {
        _isCameraInitialized = _cameraService.isInitialized;
        _state = _cameraService.isInitialized
            ? SignRecognitionState.ready
            : SignRecognitionState.error;
        _statusText = 'Ready';
      });
    }
  }

  /// Start capture workflow when shutter button is pressed
  Future<void> _startRecording() async {
    if (!_cameraService.isInitialized || _state == SignRecognitionState.recording) return;

    _pauseGlobalVoice();

    setState(() {
      _state = SignRecognitionState.recording;
      _statusText = 'Recording';
      _recordingMilliseconds = 0;
      _recognizedSign = null;
      _recognitionConfidence = 0.0;
      _feedbackDetail = null;
      _capturedFrames.clear();
      _lastSampledTime = null;
    });

    // Start image stream to sample gesture frames
    await _cameraService.startImageStream((CameraImage image) {
      if (_state != SignRecognitionState.recording) return;

      final now = DateTime.now();
      // Sample 1 frame every 200ms (~5 FPS across the recording window)
      if (_lastSampledTime == null || now.difference(_lastSampledTime!) >= const Duration(milliseconds: 200)) {
        _lastSampledTime = now;
        final inputImage = _convertCameraImageToInputImage(image);
        if (inputImage != null) {
          _capturedFrames.add(inputImage);
        }
      }
    });

    // Start 100ms ticker for elapsed time display and max duration countdown
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _recordingMilliseconds += 100;
      });

      if (_recordingMilliseconds >= _maxRecordingMs) {
        timer.cancel();
        _stopRecording(analyze: true);
      }
    });
  }

  /// Stop recording and trigger sequence recognition
  Future<void> _stopRecording({bool analyze = true}) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    await _cameraService.stopImageStream();

    if (!analyze || !mounted) {
      _resumeGlobalVoice();
      setState(() {
        _state = SignRecognitionState.ready;
        _statusText = 'Ready';
      });
      return;
    }

    await _analyzeCapturedSequence();
  }

  /// Run pose extraction and TFLite neural sequence recognition
  Future<void> _analyzeCapturedSequence() async {
    setState(() {
      _state = SignRecognitionState.analyzing;
      _statusText = 'Analyzing';
    });

    try {
      final framesToAnalyze = List<InputImage>.from(_capturedFrames);
      debugPrint('[SIGN_TO_TEXT] Analyzing sequence of ${framesToAnalyze.length} captured frames...');

      final detailedResult = await _islService.processSequenceDetailed(framesToAnalyze);

      if (!mounted) return;

      if (detailedResult.isSuccess && detailedResult.result != null) {
        final formatted = _formatSignDisplayName(detailedResult.result!.signName);
        setState(() {
          _state = SignRecognitionState.recognized;
          _statusText = 'Recognized';
          _recognizedSign = formatted;
          _recognitionConfidence = detailedResult.result!.confidence;
          _feedbackDetail = null;
        });

        if (_autoSpeakEnabled && !_ttsService.isSpeaking) {
          _ttsService.speak(formatted);
        }
      } else if (detailedResult.status == SequenceRecognitionStatus.noLandmarksDetected) {
        setState(() {
          _state = SignRecognitionState.handsNotDetected;
          _statusText = 'Hands or body not detected';
          _recognizedSign = null;
          _recognitionConfidence = 0.0;
          _feedbackDetail = 'Ensure your upper body, arms, and hands are visible in frame.';
        });
      } else {
        setState(() {
          _state = SignRecognitionState.couldNotRecognize;
          _statusText = 'Could not recognize sign';
          _recognizedSign = null;
          _recognitionConfidence = detailedResult.topCandidateConfidence ?? 0.0;
          _feedbackDetail = 'The model could not classify the sign with high confidence.';
        });
      }
    } catch (e) {
      debugPrint('[SIGN_TO_TEXT] Analysis error: $e');
      if (mounted) {
        setState(() {
          _state = SignRecognitionState.couldNotRecognize;
          _statusText = 'Could not recognize sign';
          _feedbackDetail = 'Processing encountered an error: $e';
        });
      }
    } finally {
      _capturedFrames.clear();
      _resumeGlobalVoice();
    }
  }

  /// Pick and process an original ISL video from device storage
  Future<void> _pickAndAnalyzeVideo() async {
    if (_state == SignRecognitionState.recording || _state == SignRecognitionState.analyzing) return;

    _pauseGlobalVoice();

    try {
      final PlatformFile? pickedFile = await FilePicker.pickFile(
        type: FileType.video,
      );

      if (pickedFile == null || pickedFile.path == null) {
        debugPrint('[SIGN_TO_TEXT] Video selection cancelled.');
        _resumeGlobalVoice();
        return;
      }

      final videoPath = pickedFile.path!;
      debugPrint('[SIGN_TO_TEXT] Selected video for ISL recognition: $videoPath');

      setState(() {
        _state = SignRecognitionState.analyzing;
        _statusText = 'Extracting video frames...';
        _recognizedSign = null;
        _recognitionConfidence = 0.0;
        _feedbackDetail = null;
      });

      // Extract original frames directly via platform channel MediaMetadataRetriever
      const channel = MethodChannel('com.example.adiuva/emergency');
      final dynamic framePathsRaw = await channel.invokeMethod('extractVideoFrames', {
        'videoPath': videoPath,
        'maxFrames': 18,
      });

      if (framePathsRaw is! List || framePathsRaw.isEmpty) {
        debugPrint('[SIGN_TO_TEXT] No frames extracted from video.');
        if (mounted) {
          setState(() {
            _state = SignRecognitionState.couldNotRecognize;
            _statusText = 'Could not decode video';
            _feedbackDetail = 'Could not extract frames from the selected video.';
          });
        }
        _resumeGlobalVoice();
        return;
      }

      final List<String> framePaths = framePathsRaw.cast<String>();
      debugPrint('[SIGN_TO_TEXT] Extracted ${framePaths.length} video frames for analysis.');

      setState(() {
        _statusText = 'Analyzing sign...';
      });

      final List<InputImage> videoInputImages = [];
      for (final p in framePaths) {
        videoInputImages.add(InputImage.fromFilePath(p));
      }

      final detailedResult = await _islService.processSequenceDetailed(videoInputImages);

      // Clean up temporary extracted frames
      for (final p in framePaths) {
        try {
          final f = File(p);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }

      if (!mounted) return;

      if (detailedResult.isSuccess && detailedResult.result != null) {
        final formatted = _formatSignDisplayName(detailedResult.result!.signName);
        setState(() {
          _state = SignRecognitionState.recognized;
          _statusText = 'Recognized';
          _recognizedSign = formatted;
          _recognitionConfidence = detailedResult.result!.confidence;
          _feedbackDetail = null;
        });

        if (_autoSpeakEnabled && !_ttsService.isSpeaking) {
          _ttsService.speak(formatted);
        }
      } else if (detailedResult.status == SequenceRecognitionStatus.noLandmarksDetected) {
        setState(() {
          _state = SignRecognitionState.handsNotDetected;
          _statusText = 'Hands or body not detected';
          _recognizedSign = null;
          _recognitionConfidence = 0.0;
          _feedbackDetail = 'Ensure upper body, arms, and hands are visible in the video.';
        });
      } else {
        setState(() {
          _state = SignRecognitionState.couldNotRecognize;
          _statusText = 'Could not recognize sign';
          _recognizedSign = null;
          _recognitionConfidence = detailedResult.topCandidateConfidence ?? 0.0;
          _feedbackDetail = 'The model could not classify the sign with high confidence.';
        });
      }
    } catch (e) {
      debugPrint('[SIGN_TO_TEXT] Video selection/analysis error: $e');
      if (mounted) {
        setState(() {
          _state = SignRecognitionState.couldNotRecognize;
          _statusText = 'Could not recognize sign';
          _feedbackDetail = 'Video processing error: $e';
        });
      }
    } finally {
      _resumeGlobalVoice();
    }
  }

  void _resetToReady() {
    setState(() {
      _state = SignRecognitionState.ready;
      _statusText = 'Ready';
      _recognizedSign = null;
      _recognitionConfidence = 0.0;
      _recordingMilliseconds = 0;
      _feedbackDetail = null;
    });
    _islService.resetTemporalBuffer();
  }

  void _speakCurrentSign() {
    if (_recognizedSign != null && _recognizedSign!.isNotEmpty) {
      _ttsService.speak(_recognizedSign!);
    }
  }

  /// Converts live CameraImage to ML Kit InputImage with proper NV21 stride handling
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final rotation = InputImageRotationValue.fromRawValue(_cameraService.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      if (image.planes.length == 1) {
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: imageSize,
            rotation: rotation,
            format: InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }

      // Android YUV420_888 to NV21 byte conversion
      final int width = image.width;
      final int height = image.height;
      final int ySize = width * height;
      final int uvSize = width * height ~/ 2;
      final Uint8List nv21 = Uint8List(ySize + uvSize);

      final Plane yPlane = image.planes[0];
      final Plane uPlane = image.planes[1];
      final Plane vPlane = image.planes[2];

      // 1. Copy Y plane handling row stride
      final int yRowStride = yPlane.bytesPerRow;
      final Uint8List yBuffer = yPlane.bytes;
      int destIndex = 0;
      for (int row = 0; row < height; row++) {
        nv21.setRange(destIndex, destIndex + width, yBuffer, row * yRowStride);
        destIndex += width;
      }

      // 2. Interleave V and U for standard NV21
      final int uRowStride = uPlane.bytesPerRow;
      final int vRowStride = vPlane.bytesPerRow;
      final int uPixelStride = uPlane.bytesPerPixel ?? 1;
      final int vPixelStride = vPlane.bytesPerPixel ?? 1;
      final Uint8List uBuffer = uPlane.bytes;
      final Uint8List vBuffer = vPlane.bytes;

      final int uvHeight = height ~/ 2;
      final int uvWidth = width ~/ 2;

      for (int row = 0; row < uvHeight; row++) {
        final int uRowOffset = row * uRowStride;
        final int vRowOffset = row * vRowStride;
        for (int col = 0; col < uvWidth; col++) {
          nv21[destIndex++] = vBuffer[vRowOffset + col * vPixelStride];
          nv21[destIndex++] = uBuffer[uRowOffset + col * uPixelStride];
        }
      }

      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );
    } catch (e) {
      debugPrint('[ISL_CAMERA] Frame conversion warning: $e');
      return null;
    }
  }

  String _formatSignDisplayName(String raw) {
    if (raw.length == 1) return 'Letter $raw';
    if (raw.startsWith('Letter ')) return raw;
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopRecording(analyze: false);
    }
  }

  @override
  void dispose() {
    _resumeGlobalVoice();
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _cameraService.disposeCamera();
    _islService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AccessibilityScaffold(
      pageTitle: 'Sign Language to Text',
      appBar: CustomAppBar(
        title: 'Sign Language to Text',
        actions: [
          // Auto Read Aloud Toggle
          IconButton(
            icon: Icon(
              _autoSpeakEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _autoSpeakEnabled ? AdiuvaColors.primaryTeal : Colors.grey,
            ),
            tooltip: _autoSpeakEnabled ? 'Auto read aloud enabled' : 'Auto read aloud disabled',
            onPressed: () {
              setState(() {
                _autoSpeakEnabled = !_autoSpeakEnabled;
              });
            },
          ),
          // Camera Switch (Front / Back Lens)
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: 'Switch camera lens',
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: ListView(
        children: [
          // 1. Live Camera Preview Container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AdiuvaSpacing.md, vertical: AdiuvaSpacing.sm),
            child: Container(
              height: 380,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _state == SignRecognitionState.recording
                      ? AdiuvaColors.error
                      : AdiuvaColors.primaryTeal.withValues(alpha: 0.3),
                  width: _state == SignRecognitionState.recording ? 3 : 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isCameraInitialized && _cameraService.controller != null)
                    Center(
                      child: CameraPreview(_cameraService.controller!),
                    )
                  else
                    _buildCameraPlaceholder(theme),

                  // Framing Guide (visible when ready or recording)
                  if (_state == SignRecognitionState.ready || _state == SignRecognitionState.recording)
                    Positioned(
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Keep upper body, arms, and hands clearly in frame',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),

                  // Recording Active Indicator & Timer
                  if (_state == SignRecognitionState.recording)
                    Positioned(
                      top: 48,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AdiuvaColors.error.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AdiuvaColors.error.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'REC 00:0${(_recordingMilliseconds / 1000).floor()} / 00:0$_recordingDurationSeconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Analyzing Loading Indicator Overlay
                  if (_state == SignRecognitionState.analyzing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.65),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AdiuvaColors.primaryTeal,
                              strokeWidth: 3.5,
                            ),
                            AdiuvaSpacing.gapMd,
                            Text(
                              _statusText,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AdiuvaSpacing.gapXs,
                            Text(
                              'Extracting pose landmarks & running ISL neural inference',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Control Bar (Shutter, Duration, Select Video, Stop Recording)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AdiuvaSpacing.md, vertical: AdiuvaSpacing.xs),
            child: _buildControlBar(theme),
          ),

          // 3. Clearly Visible Result Area: "Recognized Text"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AdiuvaSpacing.md, vertical: AdiuvaSpacing.xs),
            child: _buildResultArea(theme, isDark),
          ),

          // 4. Supported Gestures Tray (28 signs)
          Padding(
            padding: const EdgeInsets.all(AdiuvaSpacing.md),
            child: _buildSupportedVocabulary(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder(ThemeData theme) {
    if (_state == SignRecognitionState.permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AdiuvaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded, size: 48, color: AdiuvaColors.error),
              AdiuvaSpacing.gapMd,
              Text(
                'Camera Access Required',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              AdiuvaSpacing.gapSm,
              Text(
                'Sign Language to Text needs camera access to observe gestures.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapMd,
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Open App Settings'),
                onPressed: () => _cameraService.openSettings(),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: AdiuvaColors.primaryTeal),
    );
  }

  Widget _buildControlBar(ThemeData theme) {
    switch (_state) {
      case SignRecognitionState.recording:
        return Column(
          children: [
            // Linear progress indicator for the capture window
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_recordingMilliseconds / _maxRecordingMs).clamp(0.0, 1.0),
                backgroundColor: AdiuvaColors.error.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AdiuvaColors.error),
                minHeight: 6,
              ),
            ),
            AdiuvaSpacing.gapSm,
            // Accessible Stop Recording Button
            CustomButton.primary(
              label: 'Stop Recording',
              leadingIcon: Icons.stop_rounded,
              semanticHint: 'Stops gesture recording and analyzes the captured sign',
              onPressed: () => _stopRecording(analyze: true),
            ),
          ],
        );

      case SignRecognitionState.analyzing:
        return CustomButton.secondary(
          label: 'Analyzing sign...',
          leadingIcon: Icons.hourglass_top_rounded,
          onPressed: null,
        );

      case SignRecognitionState.recognized:
      case SignRecognitionState.couldNotRecognize:
      case SignRecognitionState.handsNotDetected:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomButton.primary(
                    label: 'Try Again',
                    leadingIcon: Icons.refresh_rounded,
                    onPressed: _resetToReady,
                  ),
                ),
                const SizedBox(width: AdiuvaSpacing.sm),
                Expanded(
                  child: CustomButton.secondary(
                    label: 'Select Video',
                    leadingIcon: Icons.video_library_rounded,
                    onPressed: _pickAndAnalyzeVideo,
                  ),
                ),
              ],
            ),
            if (_state == SignRecognitionState.recognized && _recognizedSign != null) ...[
              AdiuvaSpacing.gapSm,
              CustomButton.secondary(
                label: 'Read Aloud',
                leadingIcon: Icons.volume_up_rounded,
                onPressed: _speakCurrentSign,
              ),
            ],
          ],
        );

      case SignRecognitionState.ready:
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Configurable duration selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Duration:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                for (final d in [3, 5, 7])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('${d}s'),
                      selected: _recordingDurationSeconds == d,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _recordingDurationSeconds = d;
                          });
                        }
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            AdiuvaSpacing.gapSm,
            // Shutter button & Select Video option side-by-side
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomButton.secondary(
                    label: 'Select Video',
                    leadingIcon: Icons.video_library_rounded,
                    semanticHint: 'Select an ISL video from your phone gallery to analyze',
                    onPressed: _pickAndAnalyzeVideo,
                  ),
                ),
                const SizedBox(width: AdiuvaSpacing.md),
                Semantics(
                  label: 'Capture Sign',
                  button: true,
                  hint: 'Double tap to record your Indian Sign Language gesture for $_recordingDurationSeconds seconds',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _startRecording,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AdiuvaColors.primaryTeal,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AdiuvaColors.primaryTeal.withValues(alpha: 0.35),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: AdiuvaColors.primaryTeal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.videocam_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capture Sign',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildResultArea(ThemeData theme, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (_state) {
      case SignRecognitionState.recording:
        statusColor = AdiuvaColors.error;
        statusIcon = Icons.radio_button_checked_rounded;
        break;
      case SignRecognitionState.analyzing:
        statusColor = AdiuvaColors.voiceAmber;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case SignRecognitionState.recognized:
        statusColor = AdiuvaColors.primaryTeal;
        statusIcon = Icons.check_circle_rounded;
        break;
      case SignRecognitionState.handsNotDetected:
        statusColor = AdiuvaColors.voiceAmber;
        statusIcon = Icons.pan_tool_outlined;
        break;
      case SignRecognitionState.couldNotRecognize:
        statusColor = AdiuvaColors.error;
        statusIcon = Icons.error_outline_rounded;
        break;
      case SignRecognitionState.ready:
      default:
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.camera_alt_outlined;
        break;
    }

    return AdiuvaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Area Label & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recognized Text',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AdiuvaSpacing.gapSm,

          // Main Result Content
          if (_state == SignRecognitionState.recognized && _recognizedSign != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _recognizedSign!,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdiuvaColors.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_recognitionConfidence * 100).round()}% match',
                    style: const TextStyle(
                      color: AdiuvaColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_state == SignRecognitionState.handsNotDetected) ...[
            Text(
              'Hands or body not detected',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AdiuvaColors.voiceAmber,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _feedbackDetail ?? 'Keep your upper body, arms, and hands clearly in view during recording.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ] else if (_state == SignRecognitionState.couldNotRecognize) ...[
            Text(
              'Sign not recognized. Please try again',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AdiuvaColors.error,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _feedbackDetail ?? 'Keep your upper body, arms, and hands clearly in view. Try adjusting distance or lighting.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ] else if (_state == SignRecognitionState.recording) ...[
            Text(
              'Recording sign gesture...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AdiuvaColors.error,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Perform your sign clearly in front of the camera.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ] else if (_state == SignRecognitionState.analyzing) ...[
            Text(
              'Evaluating movement sequence...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AdiuvaColors.voiceAmber,
              ),
            ),
          ] else ...[
            Text(
              'Ready to recognize',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap "Capture Sign" to record from camera, or tap "Select Video" to analyze an existing recording.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportedVocabulary(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supported Gestures (${supportedSigns.length} Signs)',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: supportedSigns.map((s) {
              final displayName = _formatSignDisplayName(s);
              final isCurrent = _recognizedSign == displayName;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  label: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrent ? Colors.white : null,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: isCurrent ? AdiuvaColors.primaryTeal : null,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
