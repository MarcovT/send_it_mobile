import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:send_it_mobile/services/api_service.dart';
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
  String _errorMessage = '';
  bool _showNearbyOnly = true; // Toggle state

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // Initialize location and fetch clubs
  Future<void> _initializeLocation() async {
    await _determinePosition();
    await _fetchClubs();
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
        print('Location services are disabled, using default location');
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
          print('Location permissions are denied, using default location');
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
        print('Location permissions are permanently denied, using default location');
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
      
      print('Location obtained: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error determining position: $e, using default location');
      // Use default location if there's an error
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
        
        print('Fetching nearby clubs with location: $latitude, $longitude');
        
        // Fetch nearby clubs with location
        final clubs = await ApiService.fetchNearbyClubsAll(latitude, longitude);
        setState(() {
          _nearbyClubs = clubs;
          _isLoading = false;
        });
      } else {
        // Fetch all clubs
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

  // Toggle between nearby and all clubs
  void _toggleNearbyMode() {
    setState(() {
      _showNearbyOnly = !_showNearbyOnly;
    });
    _fetchClubs();
  }

  // Refresh clubs (and update location if needed)
  Future<void> _refreshClubs() async {
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
        title: Text(_showNearbyOnly ? 'Nearby Clubs' : 'All Clubs'),
        actions: [
          // Toggle switch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nearby',
                style: TextStyle(
                  fontSize: 14,
                  color: _showNearbyOnly ? Colors.blue : Colors.grey,
                  fontWeight: _showNearbyOnly ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Switch(
                value: _showNearbyOnly,
                onChanged: (value) => _toggleNearbyMode(),
                activeColor: Colors.blue,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Refresh button pressed');
              _refreshClubs();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
        child: Text(_showNearbyOnly ? 'No clubs found nearby.' : 'No clubs found.'),
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
}