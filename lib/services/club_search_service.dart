import '../models/clubs.dart';
import '../services/api_service.dart';

class ClubSearchService {
  static List<Club> _allClubs = [];
  static bool _isLoaded = false;
  static DateTime? _lastRefresh;
  static const Duration _refreshInterval = Duration(hours: 6);
  
  // Load all clubs once on app start
  static Future<void> loadAllClubs() async {
    if (_isLoaded && _lastRefresh != null && 
        DateTime.now().difference(_lastRefresh!) < _refreshInterval) {
      return; // Data is still fresh
    }
    
    try {
      _allClubs = await ApiService.fetchAllClubs();
      _isLoaded = true;
      _lastRefresh = DateTime.now();
      print('Loaded ${_allClubs.length} clubs for local search');
    } catch (e) {
      print('Error loading clubs: $e');
      rethrow;
    }
  }
  
  // Advanced search with multiple strategies
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
  
  // Exact match scoring
  static double _exactMatchScore(Club club, String query) {
    double score = 0.0;
    final name = club.name.toLowerCase();
    final address = club.address.toLowerCase();
    
    if (name == query) score += 100.0;
    if (address == query) score += 80.0;
    
    return score;
  }
  
  // Starts with scoring
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
  
  // Contains scoring
  static double _containsScore(Club club, String query) {
    double score = 0.0;
    final name = club.name.toLowerCase();
    final address = club.address.toLowerCase();
    
    if (name.contains(query)) score += 20.0;
    if (address.contains(query)) score += 15.0;
    
    return score;
  }
  
  // Simple fuzzy matching using Levenshtein distance
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
  
  // Word-based scoring for multi-word queries
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
  
  // Calculate Levenshtein distance for fuzzy matching
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
  
  // Get nearby clubs (for location-based results)
  static List<Club> getNearbyClubs(double latitude, double longitude, {int limit = 20}) {
    if (!_isLoaded) return [];
    
    // Calculate distance and sort
    final clubsWithDistance = _allClubs.map((club) {
      // Simple distance calculation (you might want to use a proper geo library)
      final lat1 = latitude;
      final lon1 = longitude;
      final lat2 = club.distance; // Assuming this contains latitude
      final lon2 = 0.0; // You'd need longitude from your club model
      
      // For now, use existing distance if available
      return MapEntry(club, club.distance);
    }).toList();
    
    clubsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    
    return clubsWithDistance.take(limit).map((entry) => entry.key).toList();
  }
  
  // Force refresh data
  static Future<void> refreshClubs() async {
    _isLoaded = false;
    _lastRefresh = null;
    await loadAllClubs();
  }
  
  // Get all clubs (for debugging)
  static List<Club> getAllClubs() => List.unmodifiable(_allClubs);
  
  // Check if data is loaded
  static bool get isLoaded => _isLoaded;
  
  // Get last refresh time
  static DateTime? get lastRefresh => _lastRefresh;
}