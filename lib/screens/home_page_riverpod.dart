import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:send_it/services/terms_service.dart';
import 'package:send_it/models/clubs.dart';
import 'package:send_it/widgets/club_list_item.dart';
import 'package:send_it/widgets/terms_conditions_dialog.dart';
import 'package:send_it/providers/clubs_provider.dart';
import 'dart:async';
import 'court_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Position? _currentPosition;
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

  // Check terms before initializing
  Future<void> _checkTermsAndInitialize() async {
    final accepted = await TermsService.hasAcceptedTerms();
    setState(() {
      _hasCheckedTerms = true;
      _termsAccepted = accepted;
    });

    if (!accepted) {
      if (mounted) {
        _showTermsDialog();
      }
    } else {
      _initialize();
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TermsConditionsDialog(
        onAccept: () async {
          Navigator.of(context).pop(); // Close the dialog first
          await TermsService.acceptTerms(); // Save acceptance to SharedPreferences
          setState(() {
            _termsAccepted = true;
          });
          _initialize();
        },
        onDecline: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _initialize() async {
    await _determinePosition();
    if (mounted) {
      await _fetchInitialClubs();
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentPosition = _getDefaultPosition();
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentPosition = _getDefaultPosition();
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentPosition = _getDefaultPosition();
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      setState(() {
        _currentPosition = _getDefaultPosition();
      });
    }
  }

  Position _getDefaultPosition() {
    return Position(
      latitude: -34.285933,
      longitude: 18.434878,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  Future<void> _fetchInitialClubs() async {
    final clubsNotifier = ref.read(clubsProvider.notifier);
    await clubsNotifier.fetchClubs(
      position: _currentPosition,
      nearbyOnly: true,
    );
  }

  void _toggleNearbyAll() {
    final clubsNotifier = ref.read(clubsProvider.notifier);
    clubsNotifier.toggleNearbyAll(_currentPosition);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create new timer for debouncing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final clubsNotifier = ref.read(clubsProvider.notifier);
      clubsNotifier.searchClubs(query);
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    final clubsNotifier = ref.read(clubsProvider.notifier);
    clubsNotifier.searchClubs(''); // Clear search
  }

  Future<void> _refreshClubs() async {
    final clubsNotifier = ref.read(clubsProvider.notifier);
    await clubsNotifier.refresh(_currentPosition);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the clubs state
    final clubsState = ref.watch(clubsProvider);

    if (!_hasCheckedTerms) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_termsAccepted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'Please accept terms and conditions to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showTermsDialog,
                  icon: const Icon(Icons.article),
                  label: const Text('Review Terms & Conditions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(clubsState),
      body: RefreshIndicator(
        onRefresh: _refreshClubs,
        child: _buildBody(clubsState),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ClubsState clubsState) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search clubs...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: _onSearchChanged,
            )
          : const Text(
              'SEND-IT Replays',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
      actions: [
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: _stopSearch,
          )
        else
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: _startSearch,
          ),
      ],
    );
  }

  Widget _buildBody(ClubsState clubsState) {
    if (clubsState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading nearby clubs...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (clubsState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Clubs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                clubsState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refreshClubs,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildLocationToggle(clubsState),
        Expanded(
          child: clubsState.displayedClubs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No clubs found for "$_searchQuery"'
                            : 'No clubs available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _stopSearch,
                          child: const Text('Clear search'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: clubsState.displayedClubs.length,
                  itemBuilder: (context, index) {
                    final club = clubsState.displayedClubs[index];
                    return ClubListItem(
                      key: ValueKey(club.id),
                      club: club,
                      onTap: () => _navigateToClub(club),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLocationToggle(ClubsState clubsState) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: clubsState.showNearbyOnly ? null : _toggleNearbyAll,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: clubsState.showNearbyOnly
                      ? Colors.indigo
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.near_me,
                      size: 18,
                      color: clubsState.showNearbyOnly
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nearby',
                      style: TextStyle(
                        color: clubsState.showNearbyOnly
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: clubsState.showNearbyOnly ? _toggleNearbyAll : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !clubsState.showNearbyOnly
                      ? Colors.indigo
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public,
                      size: 18,
                      color: !clubsState.showNearbyOnly
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Clubs',
                      style: TextStyle(
                        color: !clubsState.showNearbyOnly
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToClub(Club club) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourtPage(club: club),
      ),
    );
  }
}
