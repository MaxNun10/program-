import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/word.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

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
