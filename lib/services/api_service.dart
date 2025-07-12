import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../models/clubs.dart';
import '../models/court.dart';
import '../models/video_data.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.3.208:3000/api';
  
  // Fetch nearby clubs based on user location
  static Future<List<Club>> fetchNearbyClubsAll(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/clubs/nearby/$latitude/$longitude/10'),
      );
      
      print('Clubs Response status: ${response.statusCode}');
      print('Clubs Response body: ${response.body}');
      
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
      throw Exception('Error fetching nearby clubs: $e');
    }
  }
 
  // Fetch all clubs (without location filtering)
  static Future<List<Club>> fetchAllClubs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/clubs/'),
      );
      
      print('All clubs Response status: ${response.statusCode}');
      print('All clubs Response body: ${response.body}');
      
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
          print('Unexpected response format for all clubs: $decodedResponse');
          return [];
        }
      } else {
        throw Exception('Failed to load all clubs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all clubs: $e');
      throw Exception('Error fetching all clubs: $e');
    }
  }
  
  // Fetch courts for a specific club
  static Future<List<Court>> fetchClubCourts(String clubId) async {
    try {
      final url = '$baseUrl/courts'; 
      print('Fetching all courts from: $url');
      
      final response = await http.get(Uri.parse(url));
      
      print('Courts Response status: ${response.statusCode}');
      print('Courts Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        
        // Handle empty response
        if (responseBody.isEmpty) {
          print('Empty response body for courts');
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
          print('Unexpected response format for courts: $decodedData');
          return [];
        }
        
        // Filter courts by clubId
        final filteredCourts = allCourts.where((court) => court.clubId == clubId).toList();
        print('Found ${filteredCourts.length} courts for club $clubId');
        
        return filteredCourts;
      } else {
        throw Exception('Failed to load courts: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching courts: $e');
      throw Exception('Error fetching courts: $e');
    }
  }
   static Future<List<VideoData>> fetchCourtVideos(String courtId, String dateString) async {
    try {
      // Build the correct URL based on your Postman example
      final String url = '$baseUrl/courts/videos/$courtId/$dateString';
      
      print('🌐 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          // Add any auth headers if needed
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // Check if the response has the expected structure
        if (jsonResponse['status'] == 'success' && jsonResponse['results'] != null) {
          final List<dynamic> videosJson = jsonResponse['results'];
          
          print('🔍 Found ${videosJson.length} videos to parse');
          
          // Convert each video JSON to VideoData object with error handling
          List<VideoData> videos = [];
          
          for (int i = 0; i < videosJson.length; i++) {
            try {
              final videoJson = videosJson[i];
              print('📝 Parsing video $i: ${videoJson['_id']}');
              
              // Debug the problematic fields
              print('   - sponsors type: ${videoJson['sponsors'].runtimeType}, value: ${videoJson['sponsors']}');
              print('   - tags type: ${videoJson['tags'].runtimeType}, value: ${videoJson['tags']}');
              
              final video = VideoData.fromJson(videoJson);
              videos.add(video);
              print('   ✅ Successfully parsed video: ${video.title}');
            } catch (e) {
              print('   ❌ Error parsing video $i: $e');
              // Continue with other videos even if one fails
            }
          }
          
          print('✅ Successfully parsed ${videos.length} out of ${videosJson.length} videos');
          return videos;
        } else {
          print('❌ Unexpected response structure: ${jsonResponse['status']}');
          return [];
        }
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchCourtVideos: $e');
      throw Exception('Error fetching videos: $e');
    }
  }

  // Parse JSON into Club object
  static Club _parseClubs(Map<String, dynamic> json) {
    return Club(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Club',
      address: json['address'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(), 
      imageUrl: json['destination'] != null && json['filename'] != null 
          ? p.join(json['destination'], json['filename'])
          : json['imageUrl'] ?? '',
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