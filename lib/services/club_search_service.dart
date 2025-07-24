import 'dart:math' as math;
import '../models/clubs.dart';
import '../services/api_service.dart';

class ClubSearchService {
  static List<Club> _allClubs = [];
  static bool _isLoaded = false;
  static DateTime? _lastRefresh;
  static const Duration _refreshInterval = Duration(hours: 6);
  static double? _lastLatitude;
  static double? _lastLongitude;
  
  // Load all clubs once on app start with location data
  static Future<void> loadAllClubs({double? latitude, double? longitude}) async {
    // Check if we need to refresh due to location change or time
    final bool locationChanged = _hasLocationChanged(latitude, longitude);
    final bool timeExpired = _lastRefresh != null && 
        DateTime.now().difference(_lastRefresh!) >= _refreshInterval;
    
    if (_isLoaded && !locationChanged && !timeExpired) {
      return; // Data is still fresh and location hasn't changed significantly
    }
    
    try {
      if (latitude != null && longitude != null) {
        // Use the new endpoint with location for distance calculations
        _allClubs = await ApiService.fetchAllClubs(latitude, longitude);
        _lastLatitude = latitude;
        _lastLongitude = longitude;
      } else {
        // Fallback to original endpoint without location
        _allClubs = await ApiService.fetchAllClubs();
        _lastLatitude = null;
        _lastLongitude = null;
      }
      
      _isLoaded = true;
      _lastRefresh = DateTime.now();
      print('Loaded ${_allClubs.length} clubs for local search');
    } catch (e) {
      print('Error loading clubs: $e');
      rethrow;
    }
  }
  
  // Check if location has changed significantly (>1km)
  static bool _hasLocationChanged(double? newLatitude, double? newLongitude) {
    if (_lastLatitude == null || _lastLongitude == null) {
      return newLatitude != null && newLongitude != null;
    }
    
    if (newLatitude == null || newLongitude == null) {
      return false; // Don't consider it a change if we're going from location to no location
    }
    
    // Calculate distance between old and new location
    const double significantDistance = 1.0; // 1km threshold
    final double distance = _calculateDistance(
      _lastLatitude!, _lastLongitude!, 
      newLatitude, newLongitude
    );
    
    return distance > significantDistance;
  }
  
  // Simple distance calculation using Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  // Advanced search with multiple strategies (unchanged core logic)
  static List<Club> searchClubs(String query) {
    if (!_isLoaded || query.isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.length < 2) return [];
    
    // Multiple search strategies with scoring
    Map<Club, double> clubScores = {};
    
    for (final club in _allClubs) {
      double score = 0.0;
      
      // Strategy 1: Exact match (highest priority)
      score += _exactMatchScore(club, normalizedQuery);
      
      // Strategy 2: Starts with (high priority)
      score += _startsWithScore(club, normalizedQuery);
      
      // Strategy 3: Contains (medium priority)
      score += _containsScore(club, normalizedQuery);
      
      // Strategy 4: Fuzzy match (lower priority)
      score += _fuzzyMatchScore(club, normalizedQuery);
      
      // Strategy 5: Word-based search (for multi-word queries)
      score += _wordBasedScore(club, normalizedQuery);
      
      if (score > 0) {
        clubScores[club] = score;
      }
    }
    
    // Sort by score (highest first) and return top results
    final sortedClubs = clubScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedClubs.take(50).map((entry) => entry.key).toList();
  }
  
  // Word-based scoring for multi-word queries (unchanged)
  static double _exactMatchScore(Club club, String query) {
    double score = 0.0;
    final name = club.name.toLowerCase();
    final address = club.address.toLowerCase();
    
    if (name == query) score += 100.0;
    if (address == query) score += 80.0;
    
    return score;
  }
  
  // Starts with scoring (unchanged)
  static double _startsWithScore(Club club, String query) {
    double score = 0.0;
    final name = club.name.toLowerCase();
    final address = club.address.toLowerCase();
    
    if (name.startsWith(query)) score += 50.0;
    if (address.startsWith(query)) score += 30.0;
    
    // Check if any word starts with query
    final nameWords = name.split(' ');
    final addressWords = address.split(' ');
    
    for (final word in nameWords) {
      if (word.startsWith(query)) score += 40.0;
    }
    
    for (final word in addressWords) {
      if (word.startsWith(query)) score += 25.0;
    }
    
    return score;
  }
  
  // Contains scoring (unchanged)
  static double _containsScore(Club club, String query) {
    double score = 0.0;
    final name = club.name.toLowerCase();
    final address = club.address.toLowerCase();
    
    if (name.contains(query)) score += 20.0;
    if (address.contains(query)) score += 15.0;
    
    return score;
  }
  
  // Simple fuzzy matching using Levenshtein distance (unchanged)
  static double _fuzzyMatchScore(Club club, String query) {
    double score = 0.0;
    final name = club.name.toLowerCase();
    final nameWords = name.split(' ');
    
    // Check fuzzy match against each word in club name
    for (final word in nameWords) {
      final distance = _levenshteinDistance(word, query);
      final maxLength = word.length > query.length ? word.length : query.length;
      
      if (maxLength > 0) {
        final similarity = (maxLength - distance) / maxLength;
        
        // Only consider if similarity is above threshold
        if (similarity > 0.7) {
          score += similarity * 10.0;
        }
      }
    }
    
    return score;
  }
  
  // Word-based scoring for multi-word queries (unchanged)
  static double _wordBasedScore(Club club, String query) {
    final queryWords = query.split(' ').where((word) => word.isNotEmpty).toList();
    if (queryWords.length < 2) return 0.0;
    
    double score = 0.0;
    final name = club.name.toLowerCase();
    final address = club.address.toLowerCase();
    final allText = '$name $address';
    
    int matchedWords = 0;
    for (final queryWord in queryWords) {
      if (allText.contains(queryWord)) {
        matchedWords++;
      }
    }
    
    // Bonus for matching multiple words
    if (matchedWords > 1) {
      score += (matchedWords / queryWords.length) * 15.0;
    }
    
    return score;
  }
  
  // Calculate Levenshtein distance for fuzzy matching (unchanged)
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,     // deletion
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }
  
  // Get nearby clubs with improved sorting (now uses distance from Club model)
  static List<Club> getNearbyClubs({int limit = 20}) {
    if (!_isLoaded) return [];
    
    // Filter clubs that have distance data and sort by distance
    final clubsWithDistance = _allClubs
        .where((club) => club.distance > 0)
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
    
    return clubsWithDistance.take(limit).toList();
  }
  
  // Force refresh data with optional location update
  static Future<void> refreshClubs({double? latitude, double? longitude}) async {
    _isLoaded = false;
    _lastRefresh = null;
    await loadAllClubs(latitude: latitude, longitude: longitude);
  }
  
  // Get all clubs (for debugging)
  static List<Club> getAllClubs() => List.unmodifiable(_allClubs);
  
  // Check if data is loaded
  static bool get isLoaded => _isLoaded;
  
  // Get last refresh time
  static DateTime? get lastRefresh => _lastRefresh;
  
  // Get last known location
  static Map<String, double?> get lastLocation => {
    'latitude': _lastLatitude,
    'longitude': _lastLongitude,
  };
  
  // Check if we have location-based data
  static bool get hasLocationData => _lastLatitude != null && _lastLongitude != null;
}