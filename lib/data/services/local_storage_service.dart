import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalStorageService extends ChangeNotifier {
  late SharedPreferences _prefs;
  String _userPrefix = "";
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedUserId = _prefs.getString('logged_in_user_id');
    if (savedUserId != null) {
      _userPrefix = "${savedUserId}_";
      // 应用程序启动时，从 Firestore 下载最新进度
      await _fetchFromFirestore(savedUserId);
    }
  }

  // 这里的 setCurrentUser 改为 Future<void>，确保数据下载完再更新 UI
  Future<void> setCurrentUser(String userId) async {
    _userPrefix = "${userId}_";
    await _prefs.setString('logged_in_user_id', userId);

    // 切换账号后，立即从 Firestore 下载该用户的进度
    await _fetchFromFirestore(userId);
    notifyListeners();
  }

  void clearUserSession() {
    _userPrefix = "";
    _prefs.remove('logged_in_user_id');
    notifyListeners();
  }

  // 【修复 1】：直接从本地读取最原始、正确的 userId，不再使用 replaceAll 删除下划线
  String get _currentUserId {
    return _prefs.getString('logged_in_user_id') ?? "";
  }

  String _key(String baseKey) => "$_userPrefix$baseKey";

  // ─── 【修复 2】：新增从 Firestore 下载数据的逻辑 ──────────────────────────
  Future<void> _fetchFromFirestore(String userId) async {
    if (userId.isEmpty) return;
    try {
      final doc = await _db.collection('progress').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // 将云端数据保存到本地 SharedPreferences
        await _prefs.setInt(_key('user_points'), data['points'] ?? 0);
        await _prefs.setInt(
            _key('total_reading_time'), data['totalReadingTime'] ?? 0);

        if (data['readStoryIds'] != null) {
          await _prefs.setStringList(
              _key('read_stories'), List<String>.from(data['readStoryIds']));
        }
        if (data['earnedBadgeIds'] != null) {
          await _prefs.setStringList(
              _key('earned_badges'), List<String>.from(data['earnedBadgeIds']));
        }
        if (data['history'] != null) {
          await _prefs.setStringList(
              _key('activity_history'), List<String>.from(data['history']));
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
    }
  }

  // ─── Firestore sync helper (上传逻辑保持不变) ───────────────────────────
  Future<void> _syncToFirestore(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _db.collection('progress').doc(userId).set({
        'userId': userId,
        'points': getPointsForUser(userId),
        'readStoryIds': getReadStoryIdsForUser(userId),
        'earnedBadgeIds': getEarnedBadgeIdsForUser(userId),
        'totalReadingTime': getTotalReadingTimeForUser(userId),
        'history': getHistoryForUser(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync error: $e');
    }
  }

  // ─── Points ──────────────────────────────────────────────────────────────
  int getPoints() => _prefs.getInt(_key('user_points')) ?? 0;

  Future<void> addPoints(int pointsToAdd, String sourceId) async {
    List<String> rewardedIds = _prefs.getStringList(_key('rewarded_ids')) ?? [];
    if (!rewardedIds.contains(sourceId)) {
      int current = getPoints();
      await _prefs.setInt(_key('user_points'), current + pointsToAdd);
      rewardedIds.add(sourceId);
      await _prefs.setStringList(_key('rewarded_ids'), rewardedIds);
      await _addToHistory("Earned $pointsToAdd pts: $sourceId");
      await _syncToFirestore(_currentUserId);
      notifyListeners();
    }
  }

  // ─── Stories ─────────────────────────────────────────────────────────────
  List<String> getReadStoryIds() =>
      _prefs.getStringList(_key('read_stories')) ?? [];

  Future<void> markStoryAsRead(String id, String title) async {
    List<String> list = getReadStoryIds();
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList(_key('read_stories'), list);
      if (list.length == 1) await awardBadge('first_discovery');
      await _addToHistory("Read: $title");
      await _syncToFirestore(_currentUserId);
      notifyListeners();
    }
  }

  // ─── History ─────────────────────────────────────────────────────────────
  List<String> getHistory() =>
      _prefs.getStringList(_key('activity_history')) ?? [];

  Future<void> _addToHistory(String entry) async {
    List<String> history = getHistory();
    history.insert(0, entry);
    if (history.length > 20) history = history.sublist(0, 20);
    await _prefs.setStringList(_key('activity_history'), history);
  }

  // ─── Badges ──────────────────────────────────────────────────────────────
  List<String> getEarnedBadgeIds() =>
      _prefs.getStringList(_key('earned_badges')) ?? [];

  Future<void> awardBadge(String badgeId) async {
    List<String> list = getEarnedBadgeIds();
    if (!list.contains(badgeId)) {
      list.add(badgeId);
      await _prefs.setStringList(_key('earned_badges'), list);
      await _addToHistory("Badge: $badgeId");
      await _syncToFirestore(_currentUserId);
      notifyListeners();
    }
  }

  // ─── Reading time ─────────────────────────────────────────────────────────
  int getTotalReadingTime() => _prefs.getInt(_key('total_reading_time')) ?? 0;

  Future<void> addReadingTime(int minutes) async {
    int current = getTotalReadingTime();
    await _prefs.setInt(_key('total_reading_time'), current + minutes);
    await _syncToFirestore(_currentUserId);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _prefs.clear();
    notifyListeners();
  }

  // ─── Per-child reads (used by parent dashboard) ──────────────────────────
  String _childKey(String childId, String baseKey) => "${childId}_$baseKey";

  int getPointsForUser(String childId) =>
      _prefs.getInt(_childKey(childId, 'user_points')) ?? 0;

  List<String> getReadStoryIdsForUser(String childId) =>
      _prefs.getStringList(_childKey(childId, 'read_stories')) ?? [];

  List<String> getHistoryForUser(String childId) =>
      _prefs.getStringList(_childKey(childId, 'activity_history')) ?? [];

  List<String> getEarnedBadgeIdsForUser(String childId) =>
      _prefs.getStringList(_childKey(childId, 'earned_badges')) ?? [];

  int getTotalReadingTimeForUser(String childId) =>
      _prefs.getInt(_childKey(childId, 'total_reading_time')) ?? 0;
}
