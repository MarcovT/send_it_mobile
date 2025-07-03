import 'package:flutter/material.dart';
import '../models/clubs.dart';
import '../models/court.dart';
import '../services/api_service.dart';
import '../widgets/court_list_item.dart';
import 'court_calendar_page.dart';

class CourtPage extends StatefulWidget {
  final Club club;

  const CourtPage({super.key, required this.club});

  @override
  State<CourtPage> createState() => _CourtPageState();
}

class _CourtPageState extends State<CourtPage> {
  bool _isLoading = true;
  List<Court> _courts = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCourts();
  }

  // Fetch courts for the selected club
  Future<void> _fetchCourts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final courts = await ApiService.fetchClubCourts(widget.club.id);
      setState(() {
        _courts = courts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching courts: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.club.name),
              Text(
                'Select a Court',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _fetchCourts();
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('Retry button pressed');
                _fetchCourts();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_courts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No courts found for this club.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchCourts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Club info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.club.address,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.sports_tennis,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_courts.length} court${_courts.length == 1 ? '' : 's'} available',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Courts list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _courts.length,
            itemBuilder: (context, index) {
              final court = _courts[index];
              return CourtListItem(
                court: court,
                onTap: () {
                  // Navigate to court calendar page for this specific court
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourtCalendarPage(
                        club: widget.club,
                        court: court,
                      ),
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