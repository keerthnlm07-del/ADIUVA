import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Accelerometer-based multi-shake detector service for Shake-to-SOS.
/// Detects 4–5 strong, qualifying phone shakes within a configurable sliding
/// time window (e.g. 3000 ms), filters ordinary movement (walking, table drops),
/// enforces peak debounce, and incorporates cooldown & emergency-state protection.
class ShakeDetectorService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final VoidCallback onShake;

  /// Accelerometer g-force threshold for a qualifying vigorous shake.
  /// Standard 1.0g = 9.80665 m/s^2.
  /// Walking/gentle movement: ~1.2g–1.8g. Deliberate vigorous shake: > 2.7g.
  final double shakeThresholdGravity;

  /// Required number of qualifying shakes within the sliding time window.
  final int shakeCountThreshold;

  /// Sliding time window in milliseconds to accumulate qualifying shakes.
  final int shakeWindowMs;

  /// Minimum time between detected peaks in ms to avoid counting multiple
  /// samples from the same physical stroke.
  final int minTimeBetweenShakesMs;

  /// Cooldown duration in ms after triggering or cancelling to prevent duplicate triggers.
  final int cooldownMs;

  /// Optional predicate evaluated before counting shakes to verify emergency-state readiness.
  final bool Function()? canTrigger;

  final List<int> _shakeTimestamps = [];
  int _lastShakePeakTimestamp = 0;
  int _cooldownUntilTimestamp = 0;
  bool _isListening = false;
  bool _isEnabled = true;

  ShakeDetectorService({
    required this.onShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeCountThreshold = 4,
    this.shakeWindowMs = 3000,
    this.minTimeBetweenShakesMs = 200,
    this.cooldownMs = 10000,
    this.canTrigger,
  });

  bool get isListening => _isListening;
  bool get isEnabled => _isEnabled;
  int get currentShakeCount => _shakeTimestamps.length;
  bool get isInCooldown => DateTime.now().millisecondsSinceEpoch < _cooldownUntilTimestamp;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _shakeTimestamps.clear();
    }
  }

  /// Activate cooldown for specified duration (default: [cooldownMs])
  void startCooldown([int? durationMs]) {
    final dur = durationMs ?? cooldownMs;
    _cooldownUntilTimestamp = DateTime.now().millisecondsSinceEpoch + dur;
    _shakeTimestamps.clear();
    debugPrint('[SHAKE_DETECTOR] Cooldown activated for ${dur}ms');
  }

  void start() {
    if (_isListening) return;
    _isListening = true;

    try {
      _subscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          handleAccelerometerEvent(event);
        },
        onError: (e) {
          debugPrint('[SHAKE_DETECTOR] Accelerometer stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('[SHAKE_DETECTOR] Accelerometer initialization error: $e');
    }
  }

  /// Deterministic event handler for live accelerometer data and unit testing
  void handleAccelerometerEvent(AccelerometerEvent event) {
    if (!_isEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Cooldown protection
    if (now < _cooldownUntilTimestamp) {
      return;
    }

    // 2. Emergency-state protection
    if (canTrigger != null && !canTrigger!()) {
      _shakeTimestamps.clear();
      return;
    }

    // 3. Compute g-force magnitude
    final double gX = event.x / 9.80665;
    final double gY = event.y / 9.80665;
    final double gZ = event.z / 9.80665;
    final double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    // 4. Filter ordinary movement: only evaluate acceleration exceeding threshold
    if (gForce < shakeThresholdGravity) {
      return;
    }

    // 5. Debounce consecutive samples from the same physical shake stroke
    if (now - _lastShakePeakTimestamp < minTimeBetweenShakesMs) {
      return;
    }
    _lastShakePeakTimestamp = now;

    // 6. Evict old timestamps outside the sliding window
    _shakeTimestamps.removeWhere((timestamp) => now - timestamp > shakeWindowMs);

    // 7. Record qualifying shake peak
    _shakeTimestamps.add(now);
    debugPrint(
      '[SHAKE_DETECTOR] Qualifying shake peak ${_shakeTimestamps.length}/$shakeCountThreshold (gForce: ${gForce.toStringAsFixed(2)})',
    );

    // 8. Trigger when qualifying shake count threshold is met
    if (_shakeTimestamps.length >= shakeCountThreshold) {
      debugPrint(
        '[SHAKE_DETECTOR] Multi-shake threshold reached ($shakeCountThreshold shakes within ${shakeWindowMs}ms). Triggering SOS.',
      );
      _shakeTimestamps.clear();
      startCooldown(cooldownMs);
      onShake();
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    _shakeTimestamps.clear();
  }

  void reset() {
    _shakeTimestamps.clear();
    _lastShakePeakTimestamp = 0;
  }

  void dispose() {
    stop();
  }
}
