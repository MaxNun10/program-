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
      return UserProgress.fromMap(uid, doc.data()!);
    } else {
      final newProgress = UserProgress(uid: uid, xp: 0, level: 1);
      await _firestore.collection('users').doc(uid).set(newProgress.toMap());
      return newProgress;
    }
  }

  Future<UserProgress> updateUserProgress(int xpEarned) async {
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

    progress.updateStreak();

    progress.xp += xpEarned;
    final newLevel = UserProgress.calculateLevel(progress.xp);
    progress.level = newLevel;

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
