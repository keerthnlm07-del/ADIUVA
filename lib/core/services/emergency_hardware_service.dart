import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detailed result of native Android emergency hardware operations (direct SMS, direct Call)
class SosHardwareResult {
  final bool success;
  final String status; // 'sent', 'call_initiated', 'permission_denied', 'no_telephony', 'failed', 'unsupported_platform'
  final String message;

  const SosHardwareResult({
    required this.success,
    required this.status,
    required this.message,
  });

  @override
  String toString() => 'SosHardwareResult(success: $success, status: $status, message: $message)';
}

/// Service interfacing with native Android hardware for Direct SMS and Direct Phone Calling
class EmergencyHardwareService {
  static const MethodChannel _channel = MethodChannel('com.example.adiuva/emergency');

  /// Send SMS directly in the background using Android SmsManager without opening composer
  Future<SosHardwareResult> sendDirectSms({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      return const SosHardwareResult(
        success: false,
        status: 'invalid_number',
        message: 'Emergency phone number is empty or invalid.',
      );
    }

    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('[HARDWARE_SERVICE] Direct SMS is only available on Android native devices.');
      final launched = await launchSmsComposerFallback(
        phoneNumber: cleanPhone,
        message: message,
      );
      return SosHardwareResult(
        success: launched,
        status: launched ? 'composer_opened' : 'unsupported_platform',
        message: launched
            ? 'Opened SMS composer on non-Android platform.'
            : 'SMS composer not supported on this platform.',
      );
    }

    try {
      // 1. Check & Request SMS runtime permission
      var status = await Permission.sms.status;
      if (!status.isGranted) {
        status = await Permission.sms.request();
      }

      if (!status.isGranted) {
        debugPrint('[HARDWARE_SERVICE] android.permission.SEND_SMS denied by user.');
        // Attempt composer fallback
        await launchSmsComposerFallback(phoneNumber: cleanPhone, message: message);
        return const SosHardwareResult(
          success: false,
          status: 'permission_denied',
          message: 'SEND_SMS permission was denied. Opened SMS composer fallback.',
        );
      }

      // 2. Invoke native Android MethodChannel
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'sendDirectSms',
        {
          'phoneNumber': cleanPhone,
          'message': message,
        },
      );

      final bool isSuccess = result?['success'] as bool? ?? false;
      final String opStatus = result?['status'] as String? ?? 'unknown';
      final String msg = result?['message'] as String? ?? '';

      debugPrint('[HARDWARE_SERVICE] sendDirectSms response: success=$isSuccess, status=$opStatus, msg=$msg');

      if (!isSuccess) {
        // Fall back to composer if native sending failed
        await launchSmsComposerFallback(phoneNumber: cleanPhone, message: message);
      }

      return SosHardwareResult(
        success: isSuccess,
        status: opStatus,
        message: msg,
      );
    } on PlatformException catch (e) {
      debugPrint('[HARDWARE_SERVICE] PlatformException in sendDirectSms: $e');
      await launchSmsComposerFallback(phoneNumber: cleanPhone, message: message);
      return SosHardwareResult(
        success: false,
        status: 'failed',
        message: 'Platform error sending SMS: ${e.message}. Opened SMS composer.',
      );
    } catch (e) {
      debugPrint('[HARDWARE_SERVICE] Exception in sendDirectSms: $e');
      await launchSmsComposerFallback(phoneNumber: cleanPhone, message: message);
      return SosHardwareResult(
        success: false,
        status: 'failed',
        message: 'Unexpected error sending SMS: $e. Opened SMS composer.',
      );
    }
  }

  /// Initiate direct phone call using Android Intent.ACTION_CALL without requiring another tap
  Future<SosHardwareResult> makeDirectCall({
    required String phoneNumber,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      return const SosHardwareResult(
        success: false,
        status: 'invalid_number',
        message: 'Emergency phone number is empty or invalid.',
      );
    }

    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('[HARDWARE_SERVICE] Direct phone calling is only available on Android native devices.');
      final launched = await launchDialerFallback(phoneNumber: cleanPhone);
      return SosHardwareResult(
        success: launched,
        status: launched ? 'dialer_opened' : 'unsupported_platform',
        message: launched
            ? 'Opened phone dialer on non-Android platform.'
            : 'Phone calling not supported on this platform.',
      );
    }

    try {
      // 1. Check & Request CALL_PHONE runtime permission
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
      }

      if (!status.isGranted) {
        debugPrint('[HARDWARE_SERVICE] android.permission.CALL_PHONE denied by user.');
        // Attempt dialer fallback
        final launched = await launchDialerFallback(phoneNumber: cleanPhone);
        return SosHardwareResult(
          success: false,
          status: 'permission_denied',
          message: launched
              ? 'CALL_PHONE permission was denied. Opened phone dialer fallback.'
              : 'CALL_PHONE permission was denied and dialer could not be launched.',
        );
      }

      // 2. Invoke native Android MethodChannel
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'makeDirectCall',
        {
          'phoneNumber': cleanPhone,
        },
      );

      final bool isSuccess = result?['success'] as bool? ?? false;
      final String opStatus = result?['status'] as String? ?? 'unknown';
      final String msg = result?['message'] as String? ?? '';

      debugPrint('[HARDWARE_SERVICE] makeDirectCall response: success=$isSuccess, status=$opStatus, msg=$msg');

      if (!isSuccess) {
        // Fall back to dialer if direct call failed
        await launchDialerFallback(phoneNumber: cleanPhone);
      }

      return SosHardwareResult(
        success: isSuccess,
        status: opStatus,
        message: msg,
      );
    } on PlatformException catch (e) {
      debugPrint('[HARDWARE_SERVICE] PlatformException in makeDirectCall: $e');
      await launchDialerFallback(phoneNumber: cleanPhone);
      return SosHardwareResult(
        success: false,
        status: 'failed',
        message: 'Platform error placing call: ${e.message}. Opened dialer fallback.',
      );
    } catch (e) {
      debugPrint('[HARDWARE_SERVICE] Exception in makeDirectCall: $e');
      await launchDialerFallback(phoneNumber: cleanPhone);
      return SosHardwareResult(
        success: false,
        status: 'failed',
        message: 'Unexpected error placing call: $e. Opened dialer fallback.',
      );
    }
  }

  /// Fallback to standard SMS app composer via url_launcher
  Future<bool> launchSmsComposerFallback({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final encodedMsg = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$cleanPhone?body=$encodedMsg');

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[HARDWARE_SERVICE] Error opening SMS fallback: $e');
      return false;
    }
  }

  /// Fallback to standard phone dialer (ACTION_DIAL) via url_launcher
  Future<bool> launchDialerFallback({
    required String phoneNumber,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[HARDWARE_SERVICE] Error opening dialer fallback: $e');
      return false;
    }
  }

  /// Check hardware and permission capabilities
  Future<Map<String, dynamic>> checkEmergencyCapabilities() async {
    if (kIsWeb || !Platform.isAndroid) {
      return {
        'hasTelephony': false,
        'hasSmsPermission': false,
        'hasCallPermission': false,
      };
    }

    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('checkEmergencyCapabilities');
      return res ?? {};
    } catch (e) {
      debugPrint('[HARDWARE_SERVICE] Error checking emergency capabilities: $e');
      return {
        'hasTelephony': false,
        'hasSmsPermission': false,
        'hasCallPermission': false,
      };
    }
  }
}
