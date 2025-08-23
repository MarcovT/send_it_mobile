import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/video_data.dart';
import '../services/api_service.dart';
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
  bool _isSubmittingDeleteRequest = false;

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

  Future<void> _submitDeleteRequest(String name, String surname, String email) async {
    setState(() {
      _isSubmittingDeleteRequest = true;
    });

    final success = await ApiService.submitVideoDeleteRequest(
      videoId: widget.video.id,
      videoTitle: widget.video.title,
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
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showActionMenu,
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