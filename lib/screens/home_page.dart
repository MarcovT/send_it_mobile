import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:send_it_mobile/services/api_service.dart';
import 'package:send_it_mobile/services/club_search_service.dart';
import 'dart:async';
import '../models/clubs.dart';
import '../widgets/club_list_item.dart';
import 'court_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  Position? _currentPosition;
  List<Club> _nearbyClubs = [];
  List<Club> _allClubs = [];
  List<Club> _searchResults = [];
  String _errorMessage = '';
  bool _showNearbyOnly = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Debounce timer for search
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Initialize app with location and club data
  Future<void> _initializeApp() async {
    await _determinePosition();
    await _loadAllClubs();
    await _fetchClubs();
  }

  // Load all clubs for local search
  Future<void> _loadAllClubs() async {
    try {
      await ClubSearchService.loadAllClubs();
      print('Clubs loaded for local search');
    } catch (e) {
      print('Error loading clubs: $e');
      // Continue anyway - we can still use API-based approaches
    }
  }

  // Get current location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, use default location
        _currentPosition = Position(
          latitude: -28.749965,
          longitude: 24.740717,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, use default location
          _currentPosition = Position(
            latitude: -28.749965,
            longitude: 24.740717,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, use default location
        _currentPosition = Position(
          latitude: -28.749965,
          longitude: 24.740717,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      setState(() {
        _currentPosition = position;
      });
      
    } catch (e) {
      // Use default location if there's an error we need to make a default maybe middle BFN/CT/JHB?
      _currentPosition = Position(
        latitude: -28.749965,
        longitude: 24.740717,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  // Fetch clubs from API based on toggle state
  Future<void> _fetchClubs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_showNearbyOnly) {
        // Use current position if available, otherwise use default
        final latitude = _currentPosition?.latitude ?? -28.749965;
        final longitude = _currentPosition?.longitude ?? 24.740717;
                
        // Fetch nearby clubs with location
        final clubs = await ApiService.fetchNearbyClubsAll(latitude, longitude);
        setState(() {
          _nearbyClubs = clubs;
          _isLoading = false;
        });
      } else {
        // Fetch all clubs -> I am going to change this and the API functions to just use one. We can just autopopulate with the default
        // not sure what you guys think. But when they toggle the button off I want the distances to show if they allowed location permissions.
        final clubs = await ApiService.fetchAllClubs();
        setState(() {
          _allClubs = clubs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching clubs: $e';
      });
    }
  }

  // Debounced function
  void _onSearchChanged(String query) {
    // Cancel the previous timer
    _debounceTimer?.cancel();
    
    // For local search, we can use a shorter debounce
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _searchClubs(query);
    });
  }

  // Search clubs using local search service
  Future<void> _searchClubs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      // Use local search for instant results
      final results = ClubSearchService.searchClubs(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Search error: $e';
      });
    }
  }

  // Clear search
  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _searchQuery = '';
      _errorMessage = '';
    });
  }

  // Toggle between nearby and all clubs
  void _toggleNearbyMode() {
    // Clear search when toggling
    _clearSearch();
    setState(() {
      _showNearbyOnly = !_showNearbyOnly;
    });
    _fetchClubs();
  }

  // Refresh clubs (and update location if needed)
  Future<void> _refreshClubs() async {
    // Clear search when refreshing
    _clearSearch();
    
    // Refresh the local search data
    await ClubSearchService.refreshClubs();
    
    if (_showNearbyOnly) {
      // Update location first for nearby mode
      await _determinePosition();
    }
    await _fetchClubs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_searchQuery.isNotEmpty 
            ? 'Search Results' 
            : _showNearbyOnly ? 'Nearby Clubs' : 'All Clubs'),
        actions: [
          // Search icon
          IconButton(
            icon: Icon(_searchQuery.isNotEmpty ? Icons.clear : Icons.search),
            onPressed: _searchQuery.isNotEmpty ? _clearSearch : null,
          ),
          // Toggle switch (only show when not searching)
          if (_searchQuery.isEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nearby',
                  style: TextStyle(
                    fontSize: 14,
                    color: _showNearbyOnly ? const Color.fromARGB(255, 201, 224, 242) : const Color.fromARGB(255, 244, 244, 244),
                    fontWeight: _showNearbyOnly ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Switch(
                  value: _showNearbyOnly,
                  onChanged: (value) => _toggleNearbyMode(),
                  activeColor: const Color.fromARGB(255, 201, 224, 242),
                ),
              ],
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Refresh button pressed');
              _refreshClubs();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search clubs by name, location, or area...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : Icon(Icons.tune, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (query) {
                _onSearchChanged(query);
              },
            ),
          ),
          // Body content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Show search results if searching
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    // Show normal nearby/all clubs
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('Retry button pressed');
                _refreshClubs();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Get the appropriate list based on toggle state
    final currentClubs = _showNearbyOnly ? _nearbyClubs : _allClubs;

    if (currentClubs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showNearbyOnly ? 'No clubs found nearby.' : 'No clubs found.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshClubs,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _showNearbyOnly ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _showNearbyOnly ? Colors.blue.shade200 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _showNearbyOnly ? Icons.location_on : Icons.list,
                color: _showNearbyOnly ? Colors.blue : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _showNearbyOnly 
                    ? 'Showing ${currentClubs.length} clubs near you'
                    : 'Showing all ${currentClubs.length} clubs',
                style: TextStyle(
                  color: _showNearbyOnly ? Colors.blue.shade800 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Clubs list
        Expanded(
          child: ListView.builder(
            itemCount: currentClubs.length,
            itemBuilder: (context, index) {
              final club = currentClubs[index];
              return ClubListItem(
                club: club,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourtPage(club: club),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching clubs...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No clubs found for "$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search results banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Found ${_searchResults.length} clubs for "$_searchQuery"',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search results list
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final club = _searchResults[index];
              return ClubListItem(
                club: club,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourtPage(club: club),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}