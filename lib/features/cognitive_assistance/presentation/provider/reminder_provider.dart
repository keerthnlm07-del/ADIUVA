import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/services/local_storage_service.dart';

enum ReminderType { general, medication }

class ReminderItem {
  final String id;
  final String title;
  final ReminderType type;
  final DateTime dateTime;
  final String recurrence; // 'Once', 'Daily', 'Weekly', 'Monthly'
  final bool isEnabled;
  final bool isCompleted;
  
  // Medication Specific Fields
  final String? medicineName;
  final String? dosage;
  final bool isTaken;

  ReminderItem({
    required this.id,
    required this.title,
    this.type = ReminderType.general,
    required this.dateTime,
    this.recurrence = 'Daily',
    this.isEnabled = true,
    this.isCompleted = false,
    this.medicineName,
    this.dosage,
    this.isTaken = false,
  });

  ReminderItem copyWith({
    String? id,
    String? title,
    ReminderType? type,
    DateTime? dateTime,
    String? recurrence,
    bool? isEnabled,
    bool? isCompleted,
    String? medicineName,
    String? dosage,
    bool? isTaken,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      recurrence: recurrence ?? this.recurrence,
      isEnabled: isEnabled ?? this.isEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      isTaken: isTaken ?? this.isTaken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'dateTime': dateTime.toIso8601String(),
      'recurrence': recurrence,
      'isEnabled': isEnabled,
      'isCompleted': isCompleted,
      'medicineName': medicineName,
      'dosage': dosage,
      'isTaken': isTaken,
    };
  }

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: (json['type'] == 'medication') ? ReminderType.medication : ReminderType.general,
      dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ?? DateTime.now(),
      recurrence: json['recurrence'] as String? ?? 'Daily',
      isEnabled: json['isEnabled'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
      medicineName: json['medicineName'] as String?,
      dosage: json['dosage'] as String?,
      isTaken: json['isTaken'] as bool? ?? false,
    );
  }
}

class ReminderProvider extends ChangeNotifier {
  final LocalStorageService _storageService;
  static const String _storageKey = 'adiuva_reminders_key';

  List<ReminderItem> _reminders = [];
  bool _isLoading = false;

  ReminderProvider({LocalStorageService? storageService})
      : _storageService = storageService ?? LocalStorageService() {
    loadReminders();
  }

  List<ReminderItem> get reminders => List.unmodifiable(_reminders);
  bool get isLoading => _isLoading;

  List<ReminderItem> get generalReminders =>
      _reminders.where((r) => r.type == ReminderType.general).toList();

  List<ReminderItem> get medicationReminders =>
      _reminders.where((r) => r.type == ReminderType.medication).toList();

  List<ReminderItem> getRemindersForDate(DateTime date) {
    return _reminders.where((r) {
      final d = r.dateTime;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();
  }

  Future<void> loadReminders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final raw = await _storageService.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _reminders = list.map((e) => ReminderItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Default initial items
        final now = DateTime.now();
        _reminders = [
          ReminderItem(
            id: '1',
            title: 'Take Blood Pressure Pill',
            type: ReminderType.medication,
            dateTime: DateTime(now.year, now.month, now.day, 8, 0),
            medicineName: 'Amlodipine',
            dosage: '5mg',
            recurrence: 'Daily',
            isTaken: false,
          ),
          ReminderItem(
            id: '2',
            title: 'Evening Walk & Hydration',
            type: ReminderType.general,
            dateTime: DateTime(now.year, now.month, now.day, 18, 30),
            recurrence: 'Daily',
            isCompleted: false,
          ),
        ];
        await _saveRemindersToStorage();
      }
    } catch (_) {
      _reminders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveRemindersToStorage() async {
    final jsonList = _reminders.map((r) => r.toJson()).toList();
    await _storageService.saveString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> addReminder({
    required String title,
    required ReminderType type,
    required DateTime dateTime,
    String recurrence = 'Daily',
    String? medicineName,
    String? dosage,
  }) async {
    final newItem = ReminderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      type: type,
      dateTime: dateTime,
      recurrence: recurrence,
      medicineName: medicineName?.trim(),
      dosage: dosage?.trim(),
    );

    _reminders.insert(0, newItem);
    notifyListeners();
    await _saveRemindersToStorage();
  }

  Future<void> editReminder(String id, {String? title, DateTime? dateTime, String? recurrence}) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(
        title: title ?? _reminders[idx].title,
        dateTime: dateTime ?? _reminders[idx].dateTime,
        recurrence: recurrence ?? _reminders[idx].recurrence,
      );
      notifyListeners();
      await _saveRemindersToStorage();
    }
  }

  Future<void> toggleEnable(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(isEnabled: !_reminders[idx].isEnabled);
      notifyListeners();
      await _saveRemindersToStorage();
    }
  }

  Future<void> toggleMedicationTaken(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(isTaken: !_reminders[idx].isTaken);
      notifyListeners();
      await _saveRemindersToStorage();
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    await _saveRemindersToStorage();
  }
}
