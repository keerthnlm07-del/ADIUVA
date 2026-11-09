import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/services/local_storage_service.dart';

class TaskItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;

  TaskItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
    );
  }
}

class TodoProvider extends ChangeNotifier {
  final LocalStorageService _storageService;
  static const String _storageKey = 'adiuva_daily_tasks_key';

  List<TaskItem> _tasks = [];
  bool _isLoading = false;

  TodoProvider({LocalStorageService? storageService})
      : _storageService = storageService ?? LocalStorageService() {
    loadTasks();
  }

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;

  List<TaskItem> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      final d = t.createdAt;
      return (d.year == now.year && d.month == now.month && d.day == now.day) || !t.isCompleted;
    }).toList();
  }

  List<TaskItem> get upcomingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<TaskItem> get completedTasks => _tasks.where((t) => t.isCompleted).toList();

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final raw = await _storageService.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _tasks = list.map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Default initial task items for new installation
        _tasks = [
          TaskItem(id: '1', title: 'Take morning vitamins', isCompleted: true, createdAt: DateTime.now()),
          TaskItem(id: '2', title: 'Drink a glass of water', isCompleted: true, createdAt: DateTime.now()),
          TaskItem(id: '3', title: 'Go for a 15-minute walk', isCompleted: false, createdAt: DateTime.now()),
          TaskItem(id: '4', title: 'Call family or caregiver', isCompleted: false, createdAt: DateTime.now()),
        ];
        await _saveTasksToStorage();
      }
    } catch (_) {
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveTasksToStorage() async {
    final jsonList = _tasks.map((t) => t.toJson()).toList();
    await _storageService.saveString(_storageKey, jsonEncode(jsonList));
  }

  Future<TaskItem> addTask(String title, {DateTime? dueDate}) async {
    final clean = title.trim();
    if (clean.isEmpty) return TaskItem(id: '', title: '', createdAt: DateTime.now());

    final newTask = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: clean,
      isCompleted: false,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );

    _tasks.insert(0, newTask);
    notifyListeners();
    await _saveTasksToStorage();
    return newTask;
  }

  Future<void> editTask(String id, String newTitle) async {
    final clean = newTitle.trim();
    if (clean.isEmpty) return;

    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(title: clean);
      notifyListeners();
      await _saveTasksToStorage();
    }
  }

  Future<void> toggleTask(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(isCompleted: !_tasks[idx].isCompleted);
      notifyListeners();
      await _saveTasksToStorage();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveTasksToStorage();
  }

  /// Normalize string for title matching (lowercase, trim, remove punctuation)
  String _normalizeForMatching(String input) {
    return input
        .replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '')
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Find a task matching a query string
  TaskItem? findMatchingTask(String query) {
    final cleanQuery = _normalizeForMatching(query);
    if (cleanQuery.isEmpty) return null;

    // 1. Exact match
    for (final task in _tasks) {
      if (_normalizeForMatching(task.title) == cleanQuery) {
        return task;
      }
    }

    // 2. Substring match
    for (final task in _tasks) {
      final normTitle = _normalizeForMatching(task.title);
      if (normTitle.contains(cleanQuery) || cleanQuery.contains(normTitle)) {
        return task;
      }
    }

    // 3. Key word overlap match
    final queryWords = cleanQuery.split(' ').where((w) => w.length >= 3 && w != 'task' && w != 'the' && w != 'my').toList();
    for (final task in _tasks) {
      final normTitle = _normalizeForMatching(task.title);
      for (final w in queryWords) {
        if (normTitle.contains(w)) {
          return task;
        }
      }
    }

    return null;
  }

  /// Complete a task by query title matching
  Future<TaskItem?> completeTaskByTitle(String query) async {
    final task = findMatchingTask(query);
    if (task != null) {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = _tasks[idx].copyWith(isCompleted: true);
        notifyListeners();
        await _saveTasksToStorage();
        return _tasks[idx];
      }
    }
    return null;
  }

  /// Delete a task by query title matching
  Future<TaskItem?> deleteTaskByTitle(String query) async {
    final task = findMatchingTask(query);
    if (task != null) {
      _tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
      await _saveTasksToStorage();
      return task;
    }
    return null;
  }
}
