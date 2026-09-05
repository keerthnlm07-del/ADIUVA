import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// State of Camera Service Initialization
enum CameraState {
  uninitialized,
  permissionDenied,
  permissionPermanentlyDenied,
  initializing,
  ready,
  error,
}

/// ADIUVA Camera Service Wrapper
/// 
/// Responsibilities:
/// - Safe camera discovery and initialization (back camera)
/// - Exposing CameraController and preview state
/// - Flash/Torch mode toggling
/// - High resolution image capture for OCR and Scene Description
/// - On-demand permission checking via permission_handler
/// - Resource disposal without memory/hardware leaks
class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  CameraState _state = CameraState.uninitialized;
  String? _errorMessage;
  bool _isFlashOn = false;

  CameraController? get controller => _controller;
  CameraState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isFlashOn => _isFlashOn;
  bool get isInitialized => _controller != null && _controller!.value.isInitialized;

  /// Check camera permission state without auto-requesting
  Future<ph.PermissionStatus> checkPermission() async {
    return await ph.Permission.camera.status;
  }

  /// Request camera permission and initialize back camera safely
  Future<void> initializeCamera() async {
    if (_state == CameraState.initializing || isInitialized) return;

    _state = CameraState.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await ph.Permission.camera.request();
      if (status.isPermanentlyDenied) {
        _state = CameraState.permissionPermanentlyDenied;
        _errorMessage = 'Camera permission permanently denied. Please enable camera access in app settings.';
        notifyListeners();
        return;
      }

      if (!status.isGranted) {
        _state = CameraState.permissionDenied;
        _errorMessage = 'Camera permission is required to use vision assistance features.';
        notifyListeners();
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _state = CameraState.error;
        _errorMessage = 'No camera hardware found on device.';
        notifyListeners();
        return;
      }

      // Find primary back camera
      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;
      await controller.initialize();

      _state = CameraState.ready;
      notifyListeners();
    } catch (e) {
      _state = CameraState.error;
      _errorMessage = 'Camera initialization failed: $e';
      notifyListeners();
    }
  }

  /// Take picture for ML Kit OCR / Gemini
  Future<XFile?> takePicture() async {
    if (!isInitialized || _controller!.value.isTakingPicture) {
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      return image;
    } catch (e) {
      _errorMessage = 'Failed to capture image: $e';
      notifyListeners();
      return null;
    }
  }

  /// Toggle flash mode (torch / off)
  Future<void> toggleFlash() async {
    if (!isInitialized) return;

    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      notifyListeners();
    } catch (e) {
      _isFlashOn = false;
      notifyListeners();
    }
  }

  /// Open application settings if permission permanently denied
  Future<void> openSettings() async {
    await ph.openAppSettings();
  }

  int get sensorOrientation => _controller?.description.sensorOrientation ?? 90;
  bool get isStreaming => _controller?.value.isStreamingImages ?? false;

  /// Start live camera image streaming for real-time inference
  Future<void> startImageStream(onLatestImageAvailable onFrame) async {
    if (!isInitialized || isStreaming) return;
    try {
      await _controller!.startImageStream(onFrame);
      notifyListeners();
    } catch (e) {
      debugPrint('[CameraService] startImageStream error: $e');
    }
  }

  /// Stop live camera image streaming
  Future<void> stopImageStream() async {
    if (!isInitialized) return;
    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[CameraService] stopImageStream error: $e');
    }
  }

  /// Safe dispose camera controller
  Future<void> disposeCamera() async {
    if (_controller != null) {
      try {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
      } catch (_) {}
      _controller = null;
    }
    _state = CameraState.uninitialized;
  }

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }
}
