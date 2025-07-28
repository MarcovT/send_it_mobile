import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Club {
  final String id;
  final String name;
  final String address;
  final double distance;

  Club({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
  });

  // Secure base URL getter
  static String get _baseUrl {
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
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'send-it-api-key': _apiSecret,
  };

  // Create an Image URL using environment variable
  String get imageUrl => '$_baseUrl/clubs/download-club-image/$id';

  // Method to fetch image with authentication headers (returns bytes for widgets)
  static Future<http.Response> fetchClubImage(String clubId) async {
    final url = '$_baseUrl/clubs/download-club-image/$clubId';
    return await http.get(
      Uri.parse(url),
      headers: _headers,
    );
  }

  // For use with Image.network() - you'll need to implement a custom image provider
  // or use the fetchClubImage method above to get the bytes
  Map<String, String> get imageHeaders => _headers;
}