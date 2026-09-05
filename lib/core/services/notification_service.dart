import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local Notification Service for Cognitive Assistance Alarms & Reminders
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification init note: $e');
    }
  }

  /// Show immediate local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'adiuva_cognitive_channel',
      'Cognitive Reminders',
      channelDescription: 'Scheduled alarms and task reminders for cognitive assistance',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('Show notification error: $e');
    }
  }
}
