import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/lessons_service.dart';

class LessonProvider with ChangeNotifier {
  final LessonsService _lessonsService = LessonsService();

  List<LessonModel> _lessons = [];
  Map<String, Map<String, dynamic>> _progressByLesson = {};

  List<LessonModel> get lessons => _lessons;
  Map<String, Map<String, dynamic>> get progressByLesson => _progressByLesson;

  Future<void> loadLessons() async {
    _lessons = await _lessonsService.getLessons();
    notifyListeners();
  }

  Future<void> loadProgress(String uid) async {
    _progressByLesson = {};
    for (final lesson in _lessons) {
      final progress = await _lessonsService.getLessonProgress(uid, lesson.id);
      if (progress != null) {
        _progressByLesson[lesson.id] = progress;
      }
    }
    notifyListeners();
  }

  Future<LessonModel?> getLessonById(String lessonId) async {
    return await _lessonsService.getLessonById(lessonId);
  }

  Future<void> markWordLearned(String uid, String lessonId, String word) async {
    await _lessonsService.markWordLearned(uid, lessonId, word);
    final updatedProgress = await _lessonsService.getLessonProgress(
      uid,
      lessonId,
    );
    if (updatedProgress != null) {
      _progressByLesson[lessonId] = updatedProgress;
    }
    notifyListeners();
  }

  void updateLessonProgress(String lessonId, Map<String, dynamic> progress) {
    _progressByLesson[lessonId] = progress;
    notifyListeners();
  }
}
