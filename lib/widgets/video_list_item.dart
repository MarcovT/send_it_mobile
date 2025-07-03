import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/clubs.dart';
import '../models/court.dart';
import '../models/video_data.dart';

class VideoListItem extends StatelessWidget {
  final VideoData video;
  final Club club;
  final Court court;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final VoidCallback onTap;
  
  const VideoListItem({
    super.key,
    required this.video,
    required this.club,
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
            // Video placeholder with play icon
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 60,
                  color: Colors.blue,
                ),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Club: ${club.name}',
                    style: TextStyle(color: Colors.grey[700]),
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
                  // Show description if available
                  if (video.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}