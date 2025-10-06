import 'dart:collection';
import 'package:video_player/video_player.dart';
import '../models/video_data.dart';

/// Manages video player controllers with LRU (Least Recently Used) caching
/// to prevent memory leaks when swiping through multiple videos.
///
/// This class maintains a limited number of initialized controllers,
/// automatically disposing of the least recently used ones when the cache is full.
class VideoControllerManager {
  final Map<int, VideoPlayerController> _controllers = {};
  final Queue<int> _accessOrder = Queue<int>();

  /// Maximum number of video controllers to keep in memory
  /// This prevents memory leaks when swiping through many videos
  final int maxCached;

  VideoControllerManager({this.maxCached = 5});

  /// Get controller at index if it exists
  VideoPlayerController? get(int index) {
    if (_controllers.containsKey(index)) {
      // Move to end of queue (most recently used)
      _accessOrder.remove(index);
      _accessOrder.add(index);
      return _controllers[index];
    }
    return null;
  }

  /// Check if controller exists at index
  bool contains(int index) => _controllers.containsKey(index);

  /// Initialize a new video controller at the given index
  Future<VideoPlayerController> initialize(int index, VideoData video) async {
    // If already initialized, return existing controller
    if (_controllers.containsKey(index)) {
      _accessOrder.remove(index);
      _accessOrder.add(index);
      return _controllers[index]!;
    }

    // Remove oldest controller if at capacity
    if (_controllers.length >= maxCached) {
      await _removeOldest();
    }

    // Create and initialize new controller
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(video.streamingUrl),
      httpHeaders: video.streamingHeaders,
    );

    await controller.initialize();

    _controllers[index] = controller;
    _accessOrder.add(index);

    return controller;
  }

  /// Remove and dispose the least recently used controller
  Future<void> _removeOldest() async {
    if (_accessOrder.isEmpty) return;

    final oldestIndex = _accessOrder.removeFirst();
    final controller = _controllers.remove(oldestIndex);

    if (controller != null) {
      await controller.dispose();
    }
  }

  /// Dispose a specific controller
  Future<void> dispose(int index) async {
    final controller = _controllers.remove(index);
    _accessOrder.remove(index);

    if (controller != null) {
      await controller.dispose();
    }
  }

  /// Dispose all controllers and clear cache
  Future<void> disposeAll() async {
    for (var controller in _controllers.values) {
      await controller.dispose();
    }
    _controllers.clear();
    _accessOrder.clear();
  }

  /// Get the number of cached controllers
  int get cachedCount => _controllers.length;

  /// Get list of cached indices (for debugging)
  List<int> get cachedIndices => _controllers.keys.toList();
}
