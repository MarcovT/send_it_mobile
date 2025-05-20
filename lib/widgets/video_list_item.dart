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
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail
          InkWell(
            onTap: onTap,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                image: DecorationImage(
                  image: NetworkImage(video.thumbnailUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 50,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
          // Video details
          Padding(
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 4),
                Text(
                  'Duration: ${video.duration}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}