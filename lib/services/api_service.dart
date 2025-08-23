import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/clubs.dart';
import '../models/court.dart';
import '../models/video_data.dart';

class ApiService {
  // Use environment variables for sensitive data - no fallbacks for security
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL not found in environment variables. Please check your .env file.');
    }
    return url;
  }
  
  static String get apiSecret {
    final secret = dotenv.env['API_SECRET'];
    if (secret == null || secret.isEmpty) {
      throw Exception('API_SECRET not found in environment variables. Please check your .env file.');
    }
    return secret;
  }


  // Common headers for all requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'send-it-api-key': apiSecret,
  };

  // Fetch nearby clubs based on user location
  static Future<List<Club>> fetchNearbyClubsAll(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/clubs/nearby/$latitude/$longitude/10'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        // Decode the JSON once
        final Map<String, dynamic> decodedResponse = json.decode(response.body);
        
        // Access the results array
        final List<dynamic> results = decodedResponse['results'];
        
        // Map the results to Club objects
        return results.map((json) => _parseClubs(json)).toList();
      } else {
        throw Exception('Failed to load nearby clubs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Unable to connect. Please check your internet connection and try again.');
    }
  }
 
  // Fetch all clubs (without location filtering)
  static Future<List<Club>> fetchAllClubs([double? latitude, double? longitude]) async {
    try {
      String url;
      if (latitude != null && longitude != null) {
        // Use location-aware endpoint with large radius to get all clubs with distances
        url = '$baseUrl/clubs/all/$latitude/$longitude';
      } else {
        // Use original endpoint without location
        url = '$baseUrl/clubs/';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        // Decode the JSON once
        final dynamic decodedResponse = json.decode(response.body);
        
        // Handle different response formats
        if (decodedResponse is List) {
          // Direct array response
          return decodedResponse.map((json) => _parseClubs(json)).toList();
        } else if (decodedResponse is Map && decodedResponse.containsKey('results')) {
          // Response with results key
          final List<dynamic> results = decodedResponse['results'];
          return results.map((json) => _parseClubs(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load all clubs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Unable to connect. Please check your internet connection and try again.');
    }
  }
  
  // Fetch courts for a specific club
  static Future<List<Court>> fetchClubCourts(String clubId) async {
    try {
      final url = '$baseUrl/courts'; 
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        
        // Handle empty response
        if (responseBody.isEmpty) {
          return [];
        }
        
        final dynamic decodedData = json.decode(responseBody);
        
        // Handle different response formats
        List<Court> allCourts = [];
        if (decodedData is Map && decodedData.containsKey('results')) {
          // Response with results key
          final List<dynamic> resultsList = decodedData['results'];
          allCourts = resultsList.map((json) => _parseCourt(json)).toList();
        } else if (decodedData is List) {
          // Direct array response
          allCourts = decodedData.map((json) => _parseCourt(json)).toList();
        } else if (decodedData is Map && decodedData.containsKey('courts')) {
          // Response with courts key
          final List<dynamic> courtsList = decodedData['courts'];
          allCourts = courtsList.map((json) => _parseCourt(json)).toList();
        } else {
          return [];
        }
        
        // Filter courts by clubId
        final filteredCourts = allCourts.where((court) => court.clubId == clubId).toList();        
        return filteredCourts;
      } else {
        throw Exception('Failed to load courts: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to connect. Please check your internet connection and try again.');
    }
  }

  static Future<List<VideoData>> fetchCourtVideos(String courtId, String dateString) async {
    try {
      // Build the correct URL based on your Postman example
      final String url = '$baseUrl/courts/videos/$courtId/$dateString';
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // Check if the response has the expected structure
        if (jsonResponse['status'] == 'success' && jsonResponse['results'] != null) {
          final List<dynamic> videosJson = jsonResponse['results'];
          
          // Convert each video JSON to VideoData object with error handling
          List<VideoData> videos = [];
          
          for (int i = 0; i < videosJson.length; i++) {
            try {
              final videoJson = videosJson[i];
            
              final video = VideoData.fromJson(videoJson);
              videos.add(video);
            } catch (e) {
              throw Exception('Unable to connect. Please check your internet connection and try again.');
            }
          }
          
          return videos;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Unable to connect. Please check your internet connection and try again.');
    }
  }

  // Submit video deletion request
  static Future<bool> submitVideoDeleteRequest({
    required String videoId,
    required String videoTitle,
    required String name,
    required String surname,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/videos/request-deletion'),
        headers: _headers,
        body: jsonEncode({
          'videoId': videoId,
          'videoTitle': videoTitle,
          'name': name,
          'surname': surname,
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Parse JSON into Club object
  static Club _parseClubs(Map<String, dynamic> json) {
    return Club(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Club',
      address: json['address'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(), 
    );
  }
  
  // Parse JSON into Court object
  static Court _parseCourt(Map<String, dynamic> json) {
    return Court(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Court',
      clubId: json['clubId'] ?? json['club_id'] ?? '',
    );
  }
}