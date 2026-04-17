import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/data/services/local_storage_service.dart';

class StoryService extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Story> _stories = [];
  bool _isLoading = true;

  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;

  StoryService(this._localStorageService) {
    _fetchStoriesFromFirebase();
  }

  Future<void> _fetchStoriesFromFirebase() async {
    try {
      debugPrint("开始尝试从 Firestore 读取 stories...");
      _db.collection('stories').orderBy('orderIndex').snapshots().listen(
        (snapshot) {
          debugPrint("成功拿到数据！文档数量: ${snapshot.docs.length}");
          try {
            _stories = snapshot.docs.map((doc) {
              return Story.fromJson(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();
            _isLoading = false;
            notifyListeners();
          } catch (parseError) {
            debugPrint("❌ 解析 Story 数据时崩溃: $parseError");
          }
        },
        onError: (error) {
          debugPrint("❌ Firebase 读取流错误: $error");
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint("❌ 初始化加载错误: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStoriesOrder(List<Story> reorderedList) async {
    _stories = List<Story>.from(reorderedList);
    notifyListeners();

    try {
      WriteBatch batch = _db.batch();
      for (int i = 0; i < reorderedList.length; i++) {
        DocumentReference ref =
            _db.collection('stories').doc(reorderedList[i].id);
        batch.update(ref, {'orderIndex': i});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error updating story order in Firebase: $e");
    }
  }

  Future<bool> addStoryToFirebase(Story story) async {
    try {
      await _db.collection('stories').add(story.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStoryInFirebase(Story story) async {
    try {
      await _db.collection('stories').doc(story.id).update(story.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteStoryFromFirebase(String id) async {
    try {
      await _db.collection('stories').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Story getStoryById(String id) {
    return _stories.firstWhere((story) => story.id == id);
  }

  List<Story> getStoriesByTag(String tag) {
    return _stories
        .where((story) => (story.tags as List)
            .map((e) => e.toString().toLowerCase())
            .contains(tag.toLowerCase()))
        .toList();
  }
}
