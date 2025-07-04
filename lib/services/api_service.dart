import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../models/clubs.dart';
import '../models/court.dart';
import '../models/video_data.dart';

class ApiService {
  static const String baseUrl = 'http://172.24.64.1:3000/api';
  
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
      print('Error fetching nearby clubs: $e');
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
      final url = '$baseUrl/courts'; // or whatever your courts endpoint is
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
 
  // Fetch videos for a specific court and date (simplified - no time filtering on server)
  static Future<List<VideoData>> fetchCourtVideos(String courtId, DateTime date) async {
    try {
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final url = '$baseUrl/videos?courtId=$courtId&date=$formattedDate';
      print('Fetching videos from: $url');
      
      final response = await http.get(Uri.parse(url));
      
      print('Videos Response status: ${response.statusCode}');
      print('Videos Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        
        // Handle empty response
        if (responseBody.isEmpty) {
          print('Empty response body');
          return [];
        }
        
        final dynamic decodedData = json.decode(responseBody);
        
        // Handle different response formats
        if (decodedData is Map && decodedData.containsKey('results')) {
          // Response with results key (matches your API format)
          final List<dynamic> resultsList = decodedData['results'];
          return resultsList.map((json) => _parseVideo(json)).toList();
        } else if (decodedData is List) {
          // Direct array response
          return decodedData.map((json) => _parseVideo(json)).toList();
        } else if (decodedData is Map && decodedData.containsKey('videos')) {
          // Response with videos key
          final List<dynamic> videoList = decodedData['videos'];
          return videoList.map((json) => _parseVideo(json)).toList();
        } else {
          print('Unexpected response format: $decodedData');
          return [];
        }
      } else {
        throw Exception('Failed to load videos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching videos: $e');
      throw Exception('Error fetching videos: $e');
    }
  }

  // Client-side helper method to filter videos by time slot
  static List<VideoData> filterVideosByTimeSlot(List<VideoData> videos, TimeOfDay selectedTime) {
    final targetHour = selectedTime.hour;
    
    return videos.where((video) {
      // Parse the video title or timestamp to extract the hour
      // Assuming your video titles contain timestamp like "2025-06-17T19:39:38"
      try {
        // Extract timestamp from title (you might need to adjust this parsing logic)
        final title = video.title;
        final timestampMatch = RegExp(r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})').firstMatch(title);
        
        if (timestampMatch != null) {
          final timestamp = timestampMatch.group(1)!;
          final dateTime = DateTime.parse(timestamp);
          
          // Check if video hour matches selected time slot
          return dateTime.hour == targetHour;
        }
        
        // If no timestamp found, you might have other fields to check
        // For example, if you have a 'recordedAt' field in your video data
        return false;
      } catch (e) {
        print('Error parsing video timestamp: $e');
        return false;
      }
    }).toList();
  }

  // Alternative filtering method if you have a different timestamp field
  static List<VideoData> filterVideosByTimeSlotAlternative(List<VideoData> videos, TimeOfDay selectedTime) {
    final targetHour = selectedTime.hour;
    
    return videos.where((video) {
      // If your VideoData model has a DateTime field (like createdAt, recordedAt, etc.)
      // You would check that field instead of parsing the title
      
      // For now, let's assume you parse from title
      try {
        // Look for hour pattern in title (like "19:39:38")
        final timeMatch = RegExp(r'T(\d{2}):').firstMatch(video.title);
        if (timeMatch != null) {
          final hour = int.parse(timeMatch.group(1)!);
          return hour == targetHour;
        }
        return false;
      } catch (e) {
        print('Error parsing video time: $e');
        return false;
      }
    }).toList();
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
  
  // Parse JSON into VideoData object
  static VideoData _parseVideo(Map<String, dynamic> json) {
    return VideoData(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled Video',
      thumbnailUrl: '', // No thumbnail in API response
      videoUrl: '', // No video URL in API response
      duration: '00:00', // No duration in API response
      courtId: json['courtId'] ?? '',
      description: json['description'] ?? '',
      sponsors: json['sponsors'] ?? [],
      tags: json['tags'] ?? '',
    );
  }
}