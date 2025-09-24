import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WatchedVideosService {
  static const String _watchedVideosKey = 'watched_videos_with_timestamps';
  static const String _legacyWatchedVideosKey = 'watched_videos';
  static const String _lastCleanupKey = 'last_cleanup_date';
  
  static WatchedVideosService? _instance;
  static WatchedVideosService get instance {
    _instance ??= WatchedVideosService._();
    return _instance!;
  }
  
  WatchedVideosService._();
  
  Future<void> markVideoAsWatched(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final watchedVideosWithTimestamps = await _getWatchedVideosWithTimestamps();
    
    // Add video with current timestamp
    watchedVideosWithTimestamps[videoId] = DateTime.now().millisecondsSinceEpoch;
    
    // Save updated map
    final jsonString = jsonEncode(watchedVideosWithTimestamps);
    await prefs.setString(_watchedVideosKey, jsonString);
    
    // Clean up old entries if it's been a while
    await _cleanupIfNeeded();
  }
  
  Future<bool> isVideoWatched(String videoId) async {
    final watchedVideos = await getWatchedVideos();
    return watchedVideos.contains(videoId);
  }
  
  Future<Set<String>> getWatchedVideos() async {
    await _migrateLegacyData();
    final watchedVideosWithTimestamps = await _getWatchedVideosWithTimestamps();
    return watchedVideosWithTimestamps.keys.toSet();
  }
  
  Future<Map<String, int>> _getWatchedVideosWithTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_watchedVideosKey);
    
    if (jsonString == null) {
      return <String, int>{};
    }
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      // If there's an error parsing, return empty map
      return <String, int>{};
    }
  }
  
  Future<void> _migrateLegacyData() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyList = prefs.getStringList(_legacyWatchedVideosKey);
    
    if (legacyList != null && legacyList.isNotEmpty) {
      // Migrate old data with current timestamp
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final migratedData = <String, int>{};
      
      for (String videoId in legacyList) {
        migratedData[videoId] = currentTime;
      }
      
      // Save migrated data
      final jsonString = jsonEncode(migratedData);
      await prefs.setString(_watchedVideosKey, jsonString);
      
      // Remove old data
      await prefs.remove(_legacyWatchedVideosKey);
    }
  }
  
  Future<void> _cleanupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCleanup = prefs.getInt(_lastCleanupKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const fourteenDaysInMs = 1209600000; // 14 * 24 * 60 * 60 * 1000
    
    if (now - lastCleanup > fourteenDaysInMs) {
      await cleanupOldWatchedVideos();
      await prefs.setInt(_lastCleanupKey, now);
    }
  }
  
  Future<void> cleanupOldWatchedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final watchedVideosWithTimestamps = await _getWatchedVideosWithTimestamps();
    final cutoffTime = DateTime.now().millisecondsSinceEpoch - (14 * 24 * 60 * 60 * 1000);
    
    // Remove entries older than 14 days
    watchedVideosWithTimestamps.removeWhere((videoId, timestamp) => timestamp < cutoffTime);
    
    // Save cleaned up data
    final jsonString = jsonEncode(watchedVideosWithTimestamps);
    await prefs.setString(_watchedVideosKey, jsonString);
  }
  
  Future<void> clearWatchedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_watchedVideosKey);
    await prefs.remove(_lastCleanupKey);
  }
  
  Future<int> getWatchedVideosCount() async {
    final watchedVideos = await getWatchedVideos();
    return watchedVideos.length;
  }
}