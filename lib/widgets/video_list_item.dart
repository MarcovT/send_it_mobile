import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/court.dart';
import '../models/video_data.dart';

class VideoListItem extends StatelessWidget {
  final VideoData video;
  final Court court;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final VoidCallback onTap;
  
  const VideoListItem({
    super.key,
    required this.video,
    required this.court,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
            // Video details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                  'Court: ${court.name}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                  const SizedBox(height: 4),
                  Text(
                  'Date: ${DateFormat('MMM d, yyyy').format(selectedDate)} | Time: $selectedTimeSlot',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}