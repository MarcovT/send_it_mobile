import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/video_data.dart';

class VideoListItem extends StatelessWidget {
  final VideoData video;
  final VoidCallback onTap;
  final bool isWatched;
  
  const VideoListItem({
    super.key,
    required this.video,
    required this.onTap,
    this.isWatched = false,
  });
  
  @override
  Widget build(BuildContext context) {
    // Get time display from video data
    String timeDisplay = 'All Day';
    if (video.createdAt != null) {

      timeDisplay = DateFormat('HH:mm').format(video.createdAt!.toLocal());
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isWatched ? Colors.white : Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWatched ? Colors.grey.shade200 : Colors.indigo.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.sports_tennis_sharp,
                color: Colors.indigo.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Video details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time: $timeDisplay',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  if (video.title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.title.split('|').take(2).join('|').trim(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Play button with enhanced styling
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoListItemWithThumbnail extends StatelessWidget {
  final VideoData video;
  final VoidCallback onTap;
  final bool isWatched;
  
  const VideoListItemWithThumbnail({
    super.key,
    required this.video,
    required this.onTap,
    this.isWatched = false,
  });
  
  @override
  Widget build(BuildContext context) {
    String timeDisplay = 'All Day';
    if (video.createdAt != null) {
      timeDisplay = DateFormat('HH:mm').format(video.createdAt!);
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isWatched ? Colors.white : Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWatched ? Colors.grey.shade200 : Colors.indigo.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: Colors.indigo.shade600,
                    size: 30,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Video details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time: $timeDisplay',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  if (video.title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.title.split('|').take(3).join('|').trim(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Play button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}