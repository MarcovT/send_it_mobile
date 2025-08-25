import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:send_it/services/api_service.dart';
import 'package:send_it/services/club_search_service.dart';
import 'package:send_it/services/terms_service.dart';
import 'package:send_it/models/clubs.dart';
import 'package:send_it/widgets/club_list_item.dart';
import 'package:send_it/widgets/terms_conditions_dialog.dart';
import 'dart:async';
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
  
  bool _hasCheckedTerms = false;
  bool _termsAccepted = false;
  
  @override
  void initState() {
    super.initState();
    _checkTermsAndInitialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Check terms before initializing:
  Future<void> _checkTermsAndInitialize() async {
    final hasAccepted = await TermsService.hasAcceptedTerms();
    
    setState(() {
      _hasCheckedTerms = true;
      _termsAccepted = hasAccepted;
    });
    
    if (hasAccepted) {
      _initializeApp();
    } else {
      // Show terms dialog
      _showTermsDialog();
    }
  }

  // ADD THIS NEW METHOD - show the terms dialog:
  void _showTermsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => TermsConditionsDialog(
        onAccept: () async {
          await TermsService.acceptTerms();
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
          setState(() {
            _termsAccepted = true;
          });
          _initializeApp();
        },
        onDecline: () {
          Navigator.of(context).pop();
          // Show dialog again after a brief delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showDeclineDialog();
            }
          });
        },
      ),
    );
  }

  void _showDeclineDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Terms Required'),
          ],
        ),
        content: const Text(
          'You must accept the Terms & Conditions to use SEND-IT. Would you like to review them again?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showTermsDialog();
            },
            child: const Text('Review Terms'),
          ),
        ],
      ),
    );
  }

  // Initialize app with location and club data (KEEP THIS METHOD AS IS)
  Future<void> _initializeApp() async {
    await _determinePosition();
    await _loadAllClubs();
    await _fetchClubs();
  }

  // Load all clubs for local search (KEEP THIS METHOD AS IS)
  Future<void> _loadAllClubs() async {
    try {
      final latitude = _currentPosition?.latitude;
      final longitude = _currentPosition?.longitude;
      
      await ClubSearchService.loadAllClubs(
        latitude: latitude, 
        longitude: longitude
      );
    } catch (e) {
      // Continue anyway - we can still use API-based approaches
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, use default location
        _currentPosition = Position(
          latitude: -34.285933,
          longitude: 18.434878,
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
            latitude: -34.285933,
            longitude: 18.434878,
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
          latitude: -34.285933,
          longitude: 18.434878,
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
        latitude: -34.285933,
        longitude: 18.434878,
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

  // Fetch clubs from API based on toggle state (KEEP THIS METHOD AS IS)
  Future<void> _fetchClubs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
        // Use current position if available, otherwise use default
        final latitude = _currentPosition?.latitude ?? 26.2056;
        final longitude = _currentPosition?.longitude ?? 28.0337;
         
      if (_showNearbyOnly) {       
        // Fetch nearby clubs with location
        final clubs = await ApiService.fetchNearbyClubsAll(latitude, longitude);
        setState(() {
          _nearbyClubs = clubs;
          _isLoading = false;
        });
      } else {

        // Fetch all clubs -> I am going to change this and the API functions to just use one. We can just autopopulate with the default
        // not sure what you guys think. But when they toggle the button off I want the distances to show if they allowed location permissions.
        final clubs = await ApiService.fetchAllClubs(latitude, longitude);
        setState(() {
          _allClubs = clubs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to connect. Please check your internet connection and try again.';
      });
    }
  }

  // Debounced function (KEEP THIS METHOD AS IS)
  void _onSearchChanged(String query) {
    // Cancel the previous timer
    _debounceTimer?.cancel();
    
    // For local search, we can use a shorter debounce
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _searchClubs(query);
    });
  }

  // Search clubs using local search service (KEEP THIS METHOD AS IS)
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
        _errorMessage = 'Search error please try again';
      });
    }
  }

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

  void _toggleNearbyMode() {
    // Clear search when toggling
    _clearSearch();
    setState(() {
      _showNearbyOnly = !_showNearbyOnly;
    });
    _fetchClubs();
  }

  Future<void> _refreshClubs() async {
    // Clear search when refreshing
    _clearSearch();
    
    // Update location first if needed
    if (_showNearbyOnly) {
      await _determinePosition();
    }
    
    // Refresh the local search data with current location
    final latitude = _currentPosition?.latitude;
    final longitude = _currentPosition?.longitude;
    
    await ClubSearchService.refreshClubs(
      latitude: latitude,
      longitude: longitude
    );
    
    await _fetchClubs();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedTerms) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading SEND-IT...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_termsAccepted) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description,
                size: 64,
                color: Colors.indigo.shade400,
              ),
              const SizedBox(height: 20),
              Text(
                'Terms & Conditions Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please accept our terms to continue',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _showTermsDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Review Terms',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _searchQuery.isNotEmpty 
              ? 'Search Results' 
              : _showNearbyOnly ? 'Nearby Clubs' : 'All Clubs',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [          
          // Toggle switch (only show when not searching)
          if (_searchQuery.isEmpty) ...[
            Container(
              margin: const EdgeInsets.only(right: 2),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nearby',
                    style: TextStyle(
                      fontSize: 13,
                      color: _showNearbyOnly ? Colors.indigo.shade700 : Colors.grey.shade600,
                      fontWeight: _showNearbyOnly ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _showNearbyOnly,
                      onChanged: (value) => _toggleNearbyMode(),
                      activeThumbColor: Colors.indigo,
                      activeTrackColor: Colors.indigo.shade100,
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade200,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              _refreshClubs();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.indigo.shade200,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
              onChanged: (query) {
                _onSearchChanged(query);
              },
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: Colors.grey.shade200,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading clubs...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              'Retry',
              Icons.refresh,
              _refreshClubs,
              Colors.indigo,
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
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _showNearbyOnly ? 'No clubs found nearby.' : 'No clubs found.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              'Refresh',
              Icons.refresh,
              _refreshClubs,
              Colors.indigo,
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
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _showNearbyOnly ? Colors.indigo.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showNearbyOnly ? Colors.indigo.shade200 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _showNearbyOnly ? Icons.location_on : Icons.list,
                color: _showNearbyOnly ? Colors.indigo.shade600 : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _showNearbyOnly 
                    ? 'Showing ${currentClubs.length} clubs near you'
                    : 'Showing all ${currentClubs.length} clubs',
                style: TextStyle(
                  color: _showNearbyOnly ? Colors.indigo.shade700 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        // Clubs list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching clubs...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
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
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No clubs found for "$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              'Clear Search',
              Icons.clear,
              _clearSearch,
              Colors.indigo,
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
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Found ${_searchResults.length} clubs for "$_searchQuery"',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
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

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, Color color) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}