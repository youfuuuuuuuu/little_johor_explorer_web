import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService extends ChangeNotifier {
  late SharedPreferences _prefs;
  String _userPrefix = "";

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedUserId = _prefs.getString('logged_in_user_id');
    if (savedUserId != null) {
      _userPrefix = "${savedUserId}_";
    }
  }

  void setCurrentUser(String userId) {
    _userPrefix = "${userId}_";
    _prefs.setString('logged_in_user_id', userId);
    notifyListeners();
  }

  void clearUserSession() {
    _userPrefix = "";
    _prefs.remove('logged_in_user_id');
    notifyListeners();
  }

  String _key(String baseKey) => "$_userPrefix$baseKey";

  int getPoints() => _prefs.getInt(_key('user_points')) ?? 0;

  Future<void> addPoints(int pointsToAdd, String sourceId) async {
    List<String> rewardedIds = _prefs.getStringList(_key('rewarded_ids')) ?? [];

    if (!rewardedIds.contains(sourceId)) {
      int currentPoints = getPoints();
      await _prefs.setInt(_key('user_points'), currentPoints + pointsToAdd);

      rewardedIds.add(sourceId);
      await _prefs.setStringList(_key('rewarded_ids'), rewardedIds);

      _addToHistory("Earned $pointsToAdd pts: $sourceId");
      notifyListeners();
    }
  }

  List<String> getReadStoryIds() =>
      _prefs.getStringList(_key('read_stories')) ?? [];

  Future<void> markStoryAsRead(String id, String title) async {
    List<String> list = getReadStoryIds();
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList(_key('read_stories'), list);

      if (list.length == 1) {
        await awardBadge('first_discovery');
      }

      _addToHistory("Read: $title");
      notifyListeners();
    }
  }

  List<String> getHistory() =>
      _prefs.getStringList(_key('activity_history')) ?? [];

  Future<void> _addToHistory(String entry) async {
    List<String> history = getHistory();
    history.insert(0, entry);
    if (history.length > 5) history = history.sublist(0, 5);
    await _prefs.setStringList(_key('activity_history'), history);
  }

  List<String> getEarnedBadgeIds() =>
      _prefs.getStringList(_key('earned_badges')) ?? [];

  Future<void> awardBadge(String badgeId) async {
    List<String> list = getEarnedBadgeIds();
    if (!list.contains(badgeId)) {
      list.add(badgeId);
      await _prefs.setStringList(_key('earned_badges'), list);
      _addToHistory("Badge: $badgeId");
      notifyListeners();
    }
  }

  int getTotalReadingTime() => _prefs.getInt(_key('total_reading_time')) ?? 0;

  Future<void> addReadingTime(int minutes) async {
    int current = getTotalReadingTime();
    await _prefs.setInt(_key('total_reading_time'), current + minutes);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _prefs.clear();
    notifyListeners();
  }

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
