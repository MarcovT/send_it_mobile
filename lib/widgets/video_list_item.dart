import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/video_data.dart';

class VideoListItem extends StatelessWidget {
  final VideoData video;
  final VoidCallback onTap;
  
  const VideoListItem({
    super.key,
    required this.video,
    required this.onTap,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Tennis icon container (or video thumbnail if you implement it)
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
                      video.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Show additional video info if available
                  if (video.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      video.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
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
                      color: Colors.indigo.withOpacity(0.3),
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

// Optional: If you want to add video thumbnail support later
class VideoListItemWithThumbnail extends StatelessWidget {
  final VideoData video;
  final VoidCallback onTap;
  
  const VideoListItemWithThumbnail({
    super.key,
    required this.video,
    required this.onTap,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Video thumbnail (if you implement thumbnail endpoint)
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
                  // You can add thumbnail image here when available
                  // For now, showing play icon
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
                      video.title,
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