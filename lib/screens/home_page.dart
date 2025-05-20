import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/court.dart';
import '../widgets/court_list_item.dart';
import 'court_calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  Position? _currentPosition;
  List<Court> _nearbyCourts = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchNearbyCourts();
  }

  // Get current location and fetch nearby courts
  // Code to get nearby courts using GPS location. I don't know if this will work! 
  /*
Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled. Please enable them.';
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permissions are denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are permanently denied.';
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Once we have the position, fetch nearby courts
      await _fetchNearbyCourts();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error determining position: $e';
      });
    }
  }*/

  // Fetch nearby courts from API based on current location
  Future<void> _fetchNearbyCourts() async {
    /*
    if (_currentPosition == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Current position not available.';
      });
      return;
    }*/

    // try {
      // Simulate API call to get nearby courts
      // In a real app, we would replace this with an actual API call
      // await Future.delayed(const Duration(seconds: 1));
      
      // Mock data for demonstration
      final List<Court> mockCourts = [
        Court(
          id: '1',
          name: 'Docs Padel and Pickel',
          address: '123 Karington St, Kimberley',
          distance: 1.2,
          imageUrl: 'https://via.placeholder.com/150',
          latitude: 0.01,
          longitude: 0.01,
        ),
        Court(
          id: '2',
          name: 'AP Padel',
          address: 'In the KBY, City',
          distance: 2.5,
          imageUrl: 'https://via.placeholder.com/150',
          latitude: 0.01,
          longitude: 0.02,
        ),
      ];

      setState(() {
        _nearbyCourts = mockCourts;
        _isLoading = false;
      });
      /*
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching nearby courts: $e';
      });
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Courts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
           onPressed: () {
                print('Retry button pressed');
                //_determinePosition(); // You can also call your function here
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
                //_determinePosition(); // You can also call your function here
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_nearbyCourts.isEmpty) {
      return const Center(
        child: Text('No courts found nearby.'),
      );
    }

    return ListView.builder(
      itemCount: _nearbyCourts.length,
      itemBuilder: (context, index) {
        final court = _nearbyCourts[index];
        return CourtListItem(
          court: court,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourtCalendarPage(court: court),
              ),
            );
          },
        );
      },
    );
  }
}