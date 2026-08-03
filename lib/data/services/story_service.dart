import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/data/services/local_storage_service.dart';

class StoryService extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Story> _stories = [];
  bool _isLoading = true;
  StreamSubscription? _storiesSubscription;

  // 1. Add a Completer to track the initial data load
  Completer<void>? _initialLoadCompleter;

  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;

  StoryService(this._localStorageService) {
    // Start fetching immediately when the app opens
    fetchStoriesFromFirebase();
  }

  // 2. Make this method PUBLIC (remove the underscore) so other screens can await it
  Future<void> fetchStoriesFromFirebase() {
    // If a load is already in progress, return the existing Future so we don't fetch twice
    if (_initialLoadCompleter != null && !_initialLoadCompleter!.isCompleted) {
      return _initialLoadCompleter!.future;
    }

    // If we already have data loaded, return immediately
    if (!_isLoading && _stories.isNotEmpty) {
      return Future.value();
    }

    _initialLoadCompleter = Completer<void>();
    _isLoading = true;

    // Only notify if we are actually kicking off a new load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _storiesSubscription?.cancel(); // Cancel any ghost subscriptions
      _storiesSubscription =
          _db.collection('stories').orderBy('orderIndex').snapshots().listen(
        (snapshot) {
          try {
            _stories = snapshot.docs.map((doc) {
              return Story.fromJson(doc.data(), doc.id);
            }).toList();

            _isLoading = false;

            // 3. Mark the Future as COMPLETE on the first successful snapshot
            if (!_initialLoadCompleter!.isCompleted) {
              _initialLoadCompleter!.complete();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          } catch (parseError) {
            debugPrint('Error parsing story data structure: $parseError');
          }
        },
        onError: (error) {
          debugPrint('Firestore stream error: $error');
          _isLoading = false;

          // Prevent the app from hanging forever if there's an error
          if (!_initialLoadCompleter!.isCompleted) {
            _initialLoadCompleter!.complete();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        },
      );
    } catch (e) {
      debugPrint('Story fetch initialization error: $e');
      _isLoading = false;

      if (!_initialLoadCompleter!.isCompleted) {
        _initialLoadCompleter!.complete();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    // 4. Return the future so the UI can 'await' it
    return _initialLoadCompleter!.future;
  }

  @override
  void dispose() {
    _storiesSubscription?.cancel();
    super.dispose();
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
      debugPrint('Error updating story ordering matrix: $e');
    }
  }

  Future<bool> addStoryToFirebase(Story story) async {
    try {
      final DocumentReference docRef = _db.collection('stories').doc();
      Map<String, dynamic> storyJson = story.toJson();
      storyJson['id'] = docRef.id;
      await docRef.set(storyJson);
      return true;
    } catch (e) {
      debugPrint('Error adding new story artifact: $e');
      return false;
    }
  }

  Future<bool> updateStoryInFirebase(Story story) async {
    try {
      if (story.id.trim().isEmpty) {
        debugPrint(
            'Update cancelled: Story instance missing valid identification path string.');
        return false;
      }
      await _db.collection('stories').doc(story.id).update(story.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating existing story log: $e');
      return false;
    }
  }

  Future<bool> deleteStoryFromFirebase(String id) async {
    try {
      await _db.collection('stories').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error removing story record from database: $e');
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
