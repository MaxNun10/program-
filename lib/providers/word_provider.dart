import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/word.dart';
import '../services/firestore_service.dart';

class WordProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Word> _words = [];
  bool _isLoading = false;

  List<Word> get words => _words;
  bool get isLoading => _isLoading;

  Future<void> loadWords() async {
    _isLoading = true;
    notifyListeners();
    try {
      _words = await _firestoreService.getWords();
      // Cache locally
      await _saveToLocal(_words);
    } catch (e) {
      // Load from local cache if Firebase fails
      _words = await _loadFromLocal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Word>> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final wordsJson = prefs.getStringList('words') ?? [];
    return wordsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Word.fromMap('', map); // Assuming id is not needed for local
    }).toList();
  }

  Future<void> _saveToLocal(List<Word> words) async {
    final prefs = await SharedPreferences.getInstance();
    final wordsJson = words.map((w) => jsonEncode(w.toMap())).toList();
    await prefs.setStringList('words', wordsJson);
  }

  Future<void> addWord(Word word) async {
    await _firestoreService.addWord(word);
    _words.add(word);
    await _saveToLocal(_words);
    notifyListeners();
  }

  Future<void> updateWord(Word word) async {
    await _firestoreService.updateWord(word);
    int index = _words.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      _words[index] = word;
      await _saveToLocal(_words);
      notifyListeners();
    }
  }

  Future<void> deleteWord(String id) async {
    await _firestoreService.deleteWord(id);
    _words.removeWhere((w) => w.id == id);
    await _saveToLocal(_words);
    notifyListeners();
  }
}
