import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProgressService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveProgress({
    required String userId,
    required int points,
    required List<String> readStoryIds,
    required List<String> earnedBadgeIds,
    required int totalReadingTime,
    required List<String> history,
  }) async {
    try {
      await _db.collection('progress').doc(userId).set({
        'userId': userId,
        'points': points,
        'readStoryIds': readStoryIds,
        'earnedBadgeIds': earnedBadgeIds,
        'totalReadingTime': totalReadingTime,
        'history': history,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<Map<String, dynamic>?> loadProgress(String userId) async {
    try {
      final doc = await _db.collection('progress').doc(userId).get();
      if (doc.exists) return doc.data();
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
    return null;
  }

  Stream<Map<String, dynamic>?> watchProgress(String userId) {
    return _db
        .collection('progress')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
}
