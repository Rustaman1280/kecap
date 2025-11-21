import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/lesson_result.dart';
import '../models/user_progress.dart';

class UserProgressService {
  UserProgressService._();

  static final UserProgressService instance = UserProgressService._();

  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  Future<void> ensureUserDocument(User user) async {
    final docRef = _users.doc(user.uid);
    final doc = await docRef.get();
    final payload = _defaultData(user);
    if (!doc.exists) {
      await docRef.set(payload);
    } else {
      await docRef.set(payload, SetOptions(merge: true));
    }
  }

  Future<UserProgress> getOrCreateProgress(User user) async {
    final docRef = _users.doc(user.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      final data = _defaultData(user);
      await docRef.set(data);
      return UserProgress.fromMap(data);
    }
    return UserProgress.fromMap(snapshot.data()!);
  }

  Future<void> updateAfterLesson({
    required String uid,
    required int newLevelIndex,
    required LessonResult result,
  }) async {
    await _users.doc(uid).set(
      {
        'currentLevelIndex': newLevelIndex,
        'totalXp': FieldValue.increment(result.xpEarned),
        'lastStreak': result.achievedStreak,
        'heartsLeft': result.heartsLeft,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Map<String, dynamic> _defaultData(User user) {
    return {
      'uid': user.uid,
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'currentLevelIndex': 0,
      'totalXp': 0,
      'lastStreak': 0,
      'heartsLeft': 5,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
