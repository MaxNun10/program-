import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/word.dart';
import '../models/progress.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  Future<UserProgress> getUserProgress() async {
    final uid = userId;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final progress = UserProgress.fromMap(uid, data);
      var shouldSaveProgress = progress.resetDailyGoalIfNeeded();
      if (!data.containsKey('hearts') ||
          !data.containsKey('maxHearts') ||
          !data.containsKey('lastHeartRefill')) {
        shouldSaveProgress = true;
      }
      if (progress.refillHeartsIfNeeded()) {
        shouldSaveProgress = true;
      }
      final calculatedLevel = UserProgress.calculateLevel(progress.xp);
      if (progress.level != calculatedLevel) {
        progress.level = calculatedLevel;
        shouldSaveProgress = true;
      }
      if (shouldSaveProgress) {
        await _firestore.collection('users').doc(uid).set(progress.toMap());
      }
      return progress;
    } else {
      final newProgress = UserProgress(uid: uid, xp: 0, level: 1);
      newProgress.resetDailyGoalIfNeeded();
      newProgress.refillHeartsIfNeeded();
      await _firestore.collection('users').doc(uid).set(newProgress.toMap());
      return newProgress;
    }
  }

  Future<UserProgress> updateUserProgress(
    int xpEarned, {
    String? completedLessonId,
  }) async {
    final uid = userId;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    UserProgress progress;

    if (doc.exists) {
      progress = UserProgress.fromMap(uid, doc.data()!);
    } else {
      progress = UserProgress(
        uid: uid,
        xp: 0,
        level: 1,
        streak: 0,
        lastActiveDate: '',
      );
    }

    progress.resetDailyGoalIfNeeded();
    progress.refillHeartsIfNeeded();
    progress.updateStreak();

    progress.xp += xpEarned;
    progress.addDailyXp(xpEarned);
    final newLevel = UserProgress.calculateLevel(progress.xp);
    progress.level = newLevel;
    if (completedLessonId != null && completedLessonId.isNotEmpty) {
      progress.markLessonCompleted(completedLessonId);
    }

    await _firestore.collection('users').doc(uid).set(progress.toMap());

    return progress;
  }

  Future<UserProgress> loseHeart() async {
    final uid = userId;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    final progress = doc.exists
        ? UserProgress.fromMap(uid, doc.data()!)
        : UserProgress(uid: uid, xp: 0, level: 1);

    progress.loseHeart();
    await _firestore.collection('users').doc(uid).set(progress.toMap());
    return progress;
  }

  Future<UserProgress> markDailyGoalCelebrated() async {
    final uid = userId;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    final progress = doc.exists
        ? UserProgress.fromMap(uid, doc.data()!)
        : UserProgress(uid: uid, xp: 0, level: 1);

    progress.resetDailyGoalIfNeeded();
    progress.refillHeartsIfNeeded();
    progress.markDailyGoalCelebrated();
    await _firestore.collection('users').doc(uid).set(progress.toMap());
    return progress;
  }

  Future<List<Word>> getWords() async {
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('words')
        .get();

    return snapshot.docs
        .map((doc) => Word.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> addWord(Word word) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('words')
        .doc(word.id)
        .set(word.toMap());
  }

  Future<void> updateWord(Word word) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('words')
        .doc(word.id)
        .update(word.toMap());
  }

  Future<void> deleteWord(String id) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('words')
        .doc(id)
        .delete();
  }
}
