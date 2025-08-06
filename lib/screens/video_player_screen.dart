import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  bool _showControls = false;
  bool _isDownloading = false;

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

  Future<void> _downloadVideoToGallery() async {
    try {
      setState(() {
        _isDownloading = true;
      });

      _showSnackBar("Downloading video...");
      
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
          _isDownloading = false;
        });
        
        if (result['isSuccess']) {
          _showSnackBar("Video saved!");
        } else {
          throw Exception('Failed to save video');
        }
      } else {
        throw Exception('Failed to download video please make sure you are connected to the internet or try again later.');
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      _showSnackBar("Failed to save video, please try again later and make sure you are connected to the internet");
    }
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
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadVideoToGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: _buildVideoPlayer()),
          if (_isDownloading) _buildDownloadingOverlay(),
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


  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Loading your padel video...',
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
            Text("Please make sure you are connected to the internet and try again. If the problem persists, please submit an issue.", style: const TextStyle(color: Colors.grey, fontSize: 14)),
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