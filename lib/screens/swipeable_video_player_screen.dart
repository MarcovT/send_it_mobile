import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/video_data.dart';
import '../services/api_service.dart';
import '../services/watched_videos_service.dart';
import '../services/video_controller_manager.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class SwipeableVideoPlayerScreen extends StatefulWidget {
  final List<VideoData> videos;
  final int initialIndex;

  const SwipeableVideoPlayerScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<SwipeableVideoPlayerScreen> createState() => _SwipeableVideoPlayerScreenState();
}

class _SwipeableVideoPlayerScreenState extends State<SwipeableVideoPlayerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late VideoControllerManager _controllerManager;
  final Map<int, bool> _isLoading = {};
  final Map<int, bool> _hasError = {};
  final Map<int, bool> _showControls = {};
  bool _isDownloading = false;
  bool _isSubmittingDeleteRequest = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _controllerManager = VideoControllerManager(maxCached: 5);

    // Initialize the current video
    _initializeVideoAtIndex(_currentIndex);

    // Mark the initial video as watched
    _markCurrentVideoAsWatched();
  }

  Future<void> _initializeVideoAtIndex(int index) async {
    if (index < 0 || index >= widget.videos.length) return;
    if (_controllerManager.contains(index)) return; // Already initialized

    setState(() {
      _isLoading[index] = true;
      _hasError[index] = false;
      _showControls[index] = false;
    });

    try {
      final video = widget.videos[index];
      final controller = await _controllerManager.initialize(index, video);

      if (mounted) {
        setState(() {
          _isLoading[index] = false;
        });

        // Auto-play if it's the current video
        if (index == _currentIndex) {
          controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading[index] = false;
          _hasError[index] = true;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    // Pause the previous video
    final previousController = _controllerManager.get(_currentIndex);
    if (previousController != null) {
      previousController.pause();
    }

    setState(() {
      _currentIndex = index;
    });

    // Mark the new video as watched
    _markCurrentVideoAsWatched();

    // Initialize and play the new video
    final currentController = _controllerManager.get(index);
    if (currentController != null && currentController.value.isInitialized) {
      currentController.play();
    } else {
      _initializeVideoAtIndex(index);
    }

    // Pre-load adjacent videos
    _preloadAdjacentVideos(index);
  }

  void _preloadAdjacentVideos(int currentIndex) {
    // Pre-load next video
    if (currentIndex + 1 < widget.videos.length) {
      _initializeVideoAtIndex(currentIndex + 1);
    }

    // Pre-load previous video
    if (currentIndex - 1 >= 0) {
      _initializeVideoAtIndex(currentIndex - 1);
    }
  }

  Future<void> _markCurrentVideoAsWatched() async {
    final videoId = widget.videos[_currentIndex].id;
    await WatchedVideosService.instance.markVideoAsWatched(videoId);
  }

  void _togglePlayPause(int index) {
    final controller = _controllerManager.get(index);
    if (controller != null && controller.value.isInitialized) {
      setState(() {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      });
    }
  }

  void _toggleControls(int index) {
    setState(() {
      _showControls[index] = !(_showControls[index] ?? false);
    });

    if (_showControls[index] == true) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls[index] = false;
          });
        }
      });
    }
  }

  Future<void> _downloadVideoToGallery() async {
    try {
      setState(() {
        _isDownloading = true;
      });

      _showSnackBar("Downloading video...");

      final video = widget.videos[_currentIndex];
      final downloadHeaders = Map<String, String>.from(video.streamingHeaders);
      downloadHeaders['Download-Request'] = 'true';

      final response = await http.get(
        Uri.parse(video.streamingUrl),
        headers: downloadHeaders,
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final fileName = 'video_${video.id.substring(0, 8)}.mp4';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        final result = await ImageGallerySaverPlus.saveFile(
          filePath,
          name: 'video_${video.id.substring(0, 8)}',
        );

        setState(() {
          _isDownloading = false;
        });

        if (result['isSuccess']) {
          _showSnackBar("Video saved!");
        } else {
          throw Exception('Failed to save video');
        }
      } else {
        throw Exception('Failed to download video');
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      _showSnackBar("Failed to save video, please try again later and make sure you are connected to the internet");
    }
  }

  Future<void> _submitDeleteRequest(String name, String surname, String email) async {
    setState(() {
      _isSubmittingDeleteRequest = true;
    });

    final video = widget.videos[_currentIndex];
    final success = await ApiService.submitVideoDeleteRequest(
      videoId: video.id,
      videoTitle: video.title,
      name: name,
      surname: surname,
      email: email,
    );

    setState(() {
      _isSubmittingDeleteRequest = false;
    });

    if (success) {
      _showSnackBar("Delete request submitted successfully");
    } else {
      _showSnackBar("Failed to submit delete request. Please try again later.");
    }
  }

  void _showDeleteRequestForm() {
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Request Video Deletion'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: surnameController,
                        decoration: const InputDecoration(
                          labelText: 'Surname *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Surname is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email address is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'We only use this information to contact you and confirm when the deletion is completed. Please expect a response within 24-48 hours.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSubmittingDeleteRequest
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            Navigator.of(context).pop();
                            _submitDeleteRequest(
                              nameController.text.trim(),
                              surnameController.text.trim(),
                              emailController.text.trim(),
                            );
                          }
                        },
                  child: _isSubmittingDeleteRequest
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadVideoToGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Request to be deleted'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteRequestForm();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controllerManager.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentVideo = widget.videos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentVideo.createdAt != null
                  ? 'Time: ${DateFormat('HH:mm').format(currentVideo.createdAt!.toLocal())}'
                  : 'Time: All Day',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Video ${_currentIndex + 1} of ${widget.videos.length}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showActionMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.videos.length,
            itemBuilder: (context, index) {
              return _buildVideoPlayerPage(index);
            },
          ),
          if (_isDownloading) _buildDownloadingOverlay(),

          // Swipe indicator hints
          if (_currentIndex > 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 60,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_left,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 40,
                ),
              ),
            ),
          if (_currentIndex < widget.videos.length - 1)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 60,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 40,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDownloadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Downloading video...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'This will only take a few seconds',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayerPage(int index) {
    final isLoading = _isLoading[index] ?? true;
    final hasError = _hasError[index] ?? false;
    final controller = _controllerManager.get(index);
    final showControls = _showControls[index] ?? false;

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Loading your padel video...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Video Failed to Load',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please make sure you are connected to the internet and try again.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading[index] = true;
                  _hasError[index] = false;
                });
                _initializeVideoAtIndex(index);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (controller != null && controller.value.isInitialized) {
      return GestureDetector(
        onTap: () => _toggleControls(index),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),

            if (showControls || !controller.value.isPlaying)
              Container(
                color: Colors.black26,
                child: Center(
                  child: IconButton(
                    onPressed: () => _togglePlayPause(index),
                    icon: Icon(
                      controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: showControls || !controller.value.isPlaying ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(controller.value.position),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(controller.value.duration),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 35,
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        colors: const VideoProgressColors(
                          playedColor: Colors.blue,
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Text('Video failed to initialize', style: TextStyle(color: Colors.white)),
    );
  }
}
