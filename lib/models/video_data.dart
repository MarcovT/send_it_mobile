import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VideoData {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final String courtId;
  final String description;
  final String sponsors;
  final String tags;
  final DateTime? createdAt;

  VideoData({
    required this.id,
    required this.title,
    this.thumbnailUrl = '', // Default empty string since API doesn't provide this
    this.videoUrl = '', // Default empty string since API doesn't provide this
    this.duration = '', // Default empty string since API doesn't provide this
    required this.courtId,
    required this.description,
    required this.sponsors,
    required this.tags,
    this.createdAt,
  });

  // Secure base URL getter
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL not found in environment variables. Please check your .env file.');
    }
    return url;
  }

  // Secure API secret getter
  static String get _apiSecret {
    final secret = dotenv.env['API_SECRET'];
    if (secret == null || secret.isEmpty) {
      throw Exception('API_SECRET not found in environment variables. Please check your .env file.');
    }
    return secret;
  }

  // Headers for authenticated requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'send-it-api-key': _apiSecret,
  };

  // Streaming URL using environment variable
  String get streamingUrl => '$baseUrl/videos/serve-video/$id';

  // Method to fetch video stream with authentication headers
  static Future<http.Response> fetchVideoStream(String videoId) async {
    final url = '$baseUrl/videos/serve-video/$videoId';
    return await http.get(
      Uri.parse(url),
      headers: headers,
    );
  }

  // For use with video players that support custom headers
  Map<String, String> get streamingHeaders => headers;
  
  // Factory constructor to create VideoData from API JSON
  factory VideoData.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert any type to string
    String safeToString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is List) return value.toString();
      return value.toString();
    }

    return VideoData(
      id: safeToString(json['_id']),
      title: safeToString(json['title']),
      thumbnailUrl: safeToString(json['thumbnailUrl']), 
      videoUrl: safeToString(json['videoUrl']), 
      duration: safeToString(json['duration']), 
      courtId: safeToString(json['courtId']),
      description: safeToString(json['description']),
      sponsors: safeToString(json['sponsors']),
      tags: safeToString(json['tags']),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }

  // Method to convert VideoData to JSON (useful for debugging)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'duration': duration,
      'courtId': courtId,
      'description': description,
      'sponsors': sponsors,
      'tags': tags,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}