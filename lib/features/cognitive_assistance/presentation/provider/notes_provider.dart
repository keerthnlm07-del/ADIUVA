import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/services/local_storage_service.dart';

class NoteItem {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class NotesProvider extends ChangeNotifier {
  final LocalStorageService _storageService;
  static const String _storageKey = 'adiuva_notes_key';

  List<NoteItem> _notes = [];
  String _searchQuery = '';
  bool _isLoading = false;

  NotesProvider({LocalStorageService? storageService})
      : _storageService = storageService ?? LocalStorageService() {
    loadNotes();
  }

  List<NoteItem> get notes => List.unmodifiable(_notes);
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<NoteItem> get filteredNotes {
    if (_searchQuery.trim().isEmpty) return _notes;
    final q = _searchQuery.toLowerCase().trim();
    return _notes.where((n) =>
      n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final raw = await _storageService.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _notes = list.map((e) => NoteItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Default initial note
        _notes = [
          NoteItem(
            id: '1',
            title: 'House Key Location',
            content: 'The spare house key is kept in the blue box on the top bookshelf.',
            updatedAt: DateTime.now(),
          ),
          NoteItem(
            id: '2',
            title: 'Doctor Appointment Notes',
            content: 'Dr. Sharma recommends 30 minutes of mild exercise every morning.',
            updatedAt: DateTime.now(),
          ),
        ];
        await _saveNotesToStorage();
      }
    } catch (_) {
      _notes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveNotesToStorage() async {
    final jsonList = _notes.map((n) => n.toJson()).toList();
    await _storageService.saveString(_storageKey, jsonEncode(jsonList));
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addNote(String title, String content) async {
    final cleanTitle = title.trim().isEmpty ? 'Untitled Note' : title.trim();
    final newNote = NoteItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: cleanTitle,
      content: content.trim(),
      updatedAt: DateTime.now(),
    );

    _notes.insert(0, newNote);
    notifyListeners();
    await _saveNotesToStorage();
  }

  Future<void> editNote(String id, String title, String content) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notes[idx] = _notes[idx].copyWith(
        title: title.trim().isEmpty ? 'Untitled Note' : title.trim(),
        content: content.trim(),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      await _saveNotesToStorage();
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveNotesToStorage();
  }
}
