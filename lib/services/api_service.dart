import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/court.dart';
import '../models/video_data.dart';

class ApiService {
  static const String baseUrl = 'backendAPIURL';
  
  // Fetch nearby courts based on user location
  static Future<List<Court>> fetchNearbyCourts(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/courts/nearby?lat=$latitude&lng=$longitude'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => _parseCourt(json)).toList();
      } else {
        throw Exception('Failed to load nearby courts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching nearby courts: $e');
    }
  }
  
  // Fetch videos for a specific court, date and time
  static Future<List<VideoData>> fetchCourtVideos(String courtId, DateTime date, String timeSlot) async {
    try {
      // Parse the timeSlot to get the start hour (e.g., "9:00 - 10:00" -> 9)
      final startHour = int.parse(timeSlot.split(':')[0]);
      
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/videos?courtId=$courtId&date=$formattedDate&hour=$startHour'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => _parseVideo(json)).toList();
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching videos: $e');
    }
  }
  
  // Parse JSON into Court object
  static Court _parseCourt(Map<String, dynamic> json) {
    return Court(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      distance: json['distance'].toDouble(),
      imageUrl: json['image_url'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
  
  // Parse JSON into VideoData object
  static VideoData _parseVideo(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'],
      title: json['title'],
      thumbnailUrl: json['thumbnail_url'],
      videoUrl: json['video_url'],
      duration: json['duration'],
    );
  }
}