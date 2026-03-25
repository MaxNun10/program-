import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/firestore_service.dart';

class WordProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final List<Word> _words = [];

  List<Word> get words => _words;

  Future<void> addWord(Word word) async {
    await _firestoreService.addWord(word);
    _words.add(word);
    notifyListeners();
  }

  Future<void> updateWord(Word word) async {
    await _firestoreService.updateWord(word);
    int index = _words.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      _words[index] = word;
      notifyListeners();
    }
  }

  Future<void> deleteWord(String id) async {
    await _firestoreService.deleteWord(id);
    _words.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  Future<void> updateWordStats(String id, bool correct) async {
    final index = _words.indexWhere((w) => w.id == id);
    if (index != -1) {
      final word = _words[index];
      final updatedWord = word.copyWith(
        correctCount: word.correctCount + (correct ? 1 : 0),
        incorrectCount: word.incorrectCount + (correct ? 0 : 1),
      );
      await updateWord(updatedWord);
    }
  }
}
