import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/video_data.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoData video;
  
  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = false;
  bool _showShareOverlay = false;
  bool _isDownloadingForShare = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final videoUrl = widget.video.streamingUrl;
      
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl),
        httpHeaders: widget.video.streamingHeaders);
      await _controller!.initialize();
      
      setState(() {
        _isLoading = false;
      });
      
      _controller!.play();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }
/*
  void _showShareOptions() {
    setState(() {
      _showShareOverlay = true;
    });
  }*/

  void _hideShareOptions() {
    setState(() {
      _showShareOverlay = false;
    });
  }

  Future<void> _downloadVideoToGallery() async {
    try {
      setState(() {
        _isDownloadingForShare = true;
      });

      _showSnackBar("📥 Downloading video...");
      
      final response = await http.get(
        Uri.parse(widget.video.streamingUrl),
        headers: widget.video.streamingHeaders,
      );
      
      if (response.statusCode == 200) {
        // First save to temporary file
        final directory = await getTemporaryDirectory();
        final fileName = 'padel_video_${widget.video.id.substring(0, 8)}.mp4';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);
        
        // Then save to gallery
        final result = await ImageGallerySaverPlus.saveFile(
          filePath,
          name: 'padel_video_${widget.video.id.substring(0, 8)}',
        );
        
        setState(() {
          _isDownloadingForShare = false;
        });
        
        if (result['isSuccess']) {
          _showSnackBar("Video saved!");
        } else {
          throw Exception('Failed to save video');
        }
      } else {
        throw Exception('Failed to download video: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isDownloadingForShare = false;
      });
      _showSnackBar("Failed to save video: $e");
    }
  }

  // 📱 Download video to device for sharing
  Future<String?> _downloadVideoForSharing() async {
    try {
      setState(() {
        _isDownloadingForShare = true;
      });

      _showSnackBar("📥 Preparing video for sharing...");
      
      final response = await http.get(
        Uri.parse(widget.video.streamingUrl),
        headers: widget.video.streamingHeaders,
      );
      
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final fileName = 'padel_video_${widget.video.id.substring(0, 8)}.mp4';
        final file = File('${directory.path}/$fileName');
        
        await file.writeAsBytes(response.bodyBytes);
        
        setState(() {
          _isDownloadingForShare = false;
        });
        
        return file.path;
      } else {
        throw Exception('Failed to download video: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isDownloadingForShare = false;
      });
      _showSnackBar("Failed to prepare video: $e");
      return null;
    }
  }

  // 📱 Share to WhatsApp with actual video file
  Future<void> _shareToWhatsApp() async {
    try {
      final videoPath = await _downloadVideoForSharing();
      if (videoPath == null) return;

      final message = "🎾 Check out this amazing padel shot from ${widget.video.title}!";
      
      // Share video file directly to WhatsApp
      await Share.shareXFiles(
        [XFile(videoPath)],
        text: message,
        subject: "Amazing Padel Shot!",
      );
      
      _hideShareOptions();
      _showSnackBar("Shared to WhatsApp!");
      
    } catch (e) {
      _showSnackBar("Error sharing to WhatsApp: $e");
    }
  }

  // 📱 Share to Instagram Stories
  Future<void> _shareToInstagram() async {
    try {
      final videoPath = await _downloadVideoForSharing();
      if (videoPath == null) return;

      // Try Instagram-specific sharing first
      final instagramUrl = Uri.parse("instagram://story-camera");
      
      if (await canLaunchUrl(instagramUrl)) {
        // Share video file to Instagram Stories
        await Share.shareXFiles(
          [XFile(videoPath)],
          text: "Amazing padel shot!",
        );
        
        _showSnackBar("Opening Instagram Stories...");
      } else {
        // Fallback: Generic share
        await Share.shareXFiles(
          [XFile(videoPath)],
          text: "Check out this amazing padel shot!",
        );
        _showSnackBar("Instagram not installed, using generic share");
      }
      
      _hideShareOptions();
      
    } catch (e) {
      _showSnackBar("Error sharing to Instagram: $e");
    }
  }

  // 📱 Share to Facebook
  Future<void> _shareToFacebook() async {
    try {
      final videoPath = await _downloadVideoForSharing();
      if (videoPath == null) return;

      // Share video file to Facebook
      await Share.shareXFiles(
        [XFile(videoPath)],
        text: "Check out this amazing padel shot from my game!",
        subject: "Amazing Padel Shot!",
      );
      
      _hideShareOptions();
      _showSnackBar("Shared to Facebook!");
      
    } catch (e) {
      _showSnackBar("Error sharing to Facebook: $e");
    }
  }

  // 📤 Generic share with video file
  Future<void> _shareGeneric() async {
    try {
      final videoPath = await _downloadVideoForSharing();
      if (videoPath == null) return;

      await Share.shareXFiles(
        [XFile(videoPath)],
        text: "🎾 Check out this amazing padel shot!\n\n${widget.video.title}",
        subject: "Amazing Padel Shot! 🎾",
      );
      
      _hideShareOptions();
      _showSnackBar("Video ready to share!");
      
    } catch (e) {
      _showSnackBar("Error sharing video: $e");
    }
  }

  // 📋 Copy video link to clipboard
  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.video.streamingUrl));
    _showSnackBar("Video link copied to clipboard!");
    _hideShareOptions();
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.video.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          /*IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _showShareOptions,
          ),*/
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadVideoToGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: _buildVideoPlayer()),
          if (_showShareOverlay) _buildShareOverlay(),
          if (_isDownloadingForShare) _buildDownloadingOverlay(),
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
              'Preparing video for sharing...',
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

  Widget _buildShareOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Share Video',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _hideShareOptions,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Share this 30-second video with friends!',
                style: TextStyle(color: Colors.indigo, fontSize: 14),
              ),
              const SizedBox(height: 20),
              
              // Social media buttons with video sharing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: Colors.green,
                    onTap: _shareToWhatsApp,
                  ),
                  _buildShareButton(
                    icon: Icons.camera_alt,
                    label: 'Instagram',
                    color: Colors.purple,
                    onTap: _shareToInstagram,
                  ),
                  _buildShareButton(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: Colors.blue,
                    onTap: _shareToFacebook,
                  ),
                  _buildShareButton(
                    icon: Icons.save_alt,
                    label: 'Save to Photos',
                    color: Colors.teal,
                    onTap: _downloadVideoToGallery,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // More options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareButton(
                    icon: Icons.link,
                    label: 'Copy Link',
                    color: Colors.grey,
                    onTap: _copyLink,
                  ),
                  _buildShareButton(
                    icon: Icons.more_horiz,
                    label: 'More Apps',
                    color: Colors.orange,
                    onTap: _shareGeneric,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Text(
                '💡 Tip: Videos are perfect for Instagram Stories!',
                style: TextStyle(
                  color: Colors.indigo,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha:0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            '🎬 Loading your padel video...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      );
    }

    if (_hasError) {
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
            Text(_errorMessage, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _initializeVideoPlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_controller != null && _controller!.value.isInitialized) {
      return GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            
            if (_showControls || !_controller!.value.isPlaying)
              Container(
                color: Colors.black26,
                child: Center(
                  child: IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(
                      _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
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
                opacity: _showControls || !_controller!.value.isPlaying ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.blue,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const Text('Video failed to initialize', style: TextStyle(color: Colors.white));
  }
}