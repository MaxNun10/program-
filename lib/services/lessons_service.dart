import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lesson_model.dart';

class LessonsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  Future<List<LessonModel>> getLessons() async {
    final snapshot = await _firestore.collection('lessons').get();
    return snapshot.docs
        .map((doc) => LessonModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<LessonModel?> getLessonById(String lessonId) async {
    final doc = await _firestore.collection('lessons').doc(lessonId).get();
    if (doc.exists) {
      return LessonModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLessonProgress(
    String uid,
    String lessonId,
  ) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('lesson_progress')
        .doc(lessonId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> saveLessonProgress(
    String uid,
    String lessonId,
    Map<String, dynamic> progress,
  ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('lesson_progress')
        .doc(lessonId)
        .set(progress);
  }

  Future<void> markWordLearned(String uid, String lessonId, String word) async {
    final progress = await getLessonProgress(uid, lessonId) ?? {};
    final learnedWords = List<String>.from(progress['learnedWords'] ?? []);
    if (!learnedWords.contains(word)) {
      learnedWords.add(word);
    }
    progress['learnedWords'] = learnedWords;
    await saveLessonProgress(uid, lessonId, progress);
  }
}

Future<void> saveQuizScore(String uid, String lessonId, int score) async {
  final service = LessonsService();
  final progress = {'score': score, 'completed': true};
  await service.saveLessonProgress(uid, lessonId, progress);
}
