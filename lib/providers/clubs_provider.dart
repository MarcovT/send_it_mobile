import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/clubs.dart';
import '../services/api_service.dart';
import '../exceptions/app_exceptions.dart';

/// State class for clubs management
class ClubsState {
  final List<Club> nearbyClubs;
  final List<Club> allClubs;
  final List<Club> displayedClubs; // Current filtered/searched clubs
  final bool isLoading;
  final String? errorMessage;
  final Position? userPosition;
  final bool showNearbyOnly;
  final String searchQuery;

  const ClubsState({
    this.nearbyClubs = const [],
    this.allClubs = const [],
    this.displayedClubs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.userPosition,
    this.showNearbyOnly = true,
    this.searchQuery = '',
  });

  ClubsState copyWith({
    List<Club>? nearbyClubs,
    List<Club>? allClubs,
    List<Club>? displayedClubs,
    bool? isLoading,
    String? errorMessage,
    Position? userPosition,
    bool? showNearbyOnly,
    String? searchQuery,
  }) {
    return ClubsState(
      nearbyClubs: nearbyClubs ?? this.nearbyClubs,
      allClubs: allClubs ?? this.allClubs,
      displayedClubs: displayedClubs ?? this.displayedClubs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userPosition: userPosition ?? this.userPosition,
      showNearbyOnly: showNearbyOnly ?? this.showNearbyOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier for clubs state management
class ClubsNotifier extends StateNotifier<ClubsState> {
  ClubsNotifier() : super(const ClubsState());

  /// Fetch clubs based on nearby toggle
  Future<void> fetchClubs({Position? position, bool nearbyOnly = true}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (nearbyOnly && position != null) {
        // Fetch nearby clubs
        final clubs = await ApiService.fetchNearbyClubsAll(
          position.latitude,
          position.longitude,
        );
        state = state.copyWith(
          nearbyClubs: clubs,
          displayedClubs: clubs,
          isLoading: false,
          showNearbyOnly: true,
          userPosition: position,
        );
      } else {
        // Fetch all clubs
        final clubs = await ApiService.fetchAllClubs(
          position?.latitude,
          position?.longitude,
        );
        state = state.copyWith(
          allClubs: clubs,
          displayedClubs: clubs,
          isLoading: false,
          showNearbyOnly: false,
          userPosition: position,
        );
      }
    } on NetworkException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } on ClubException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Search clubs with query
  void searchClubs(String query) {
    state = state.copyWith(searchQuery: query);

    if (query.isEmpty) {
      // Show all clubs (nearby or all based on toggle)
      final clubs = state.showNearbyOnly ? state.nearbyClubs : state.allClubs;
      state = state.copyWith(displayedClubs: clubs);
      return;
    }

    // Use ClubSearchService which maintains its own internal list
    // First ensure it's loaded with the appropriate clubs
    final clubsToSearch = state.showNearbyOnly ? state.nearbyClubs : state.allClubs;

    // Manual search implementation since ClubSearchService uses internal list
    final normalizedQuery = query.toLowerCase().trim();
    final searchResults = clubsToSearch.where((club) {
      final clubName = club.name.toLowerCase();
      final clubAddress = club.address.toLowerCase();
      return clubName.contains(normalizedQuery) || clubAddress.contains(normalizedQuery);
    }).toList();

    state = state.copyWith(displayedClubs: searchResults);
  }

  /// Toggle between nearby and all clubs
  Future<void> toggleNearbyAll(Position? position) async {
    final newNearbyOnly = !state.showNearbyOnly;

    if (newNearbyOnly) {
      // Switch to nearby clubs
      if (state.nearbyClubs.isEmpty && position != null) {
        // Need to fetch nearby clubs
        await fetchClubs(position: position, nearbyOnly: true);
      } else {
        // Already have nearby clubs
        state = state.copyWith(
          displayedClubs: state.nearbyClubs,
          showNearbyOnly: true,
        );
      }
    } else {
      // Switch to all clubs
      if (state.allClubs.isEmpty) {
        // Need to fetch all clubs
        await fetchClubs(position: position, nearbyOnly: false);
      } else {
        // Already have all clubs
        state = state.copyWith(
          displayedClubs: state.allClubs,
          showNearbyOnly: false,
        );
      }
    }

    // Reapply search if there's a query
    if (state.searchQuery.isNotEmpty) {
      searchClubs(state.searchQuery);
    }
  }

  /// Refresh current clubs
  Future<void> refresh(Position? position) async {
    await fetchClubs(
      position: position,
      nearbyOnly: state.showNearbyOnly,
    );

    // Reapply search if there's a query
    if (state.searchQuery.isNotEmpty) {
      searchClubs(state.searchQuery);
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for clubs state
final clubsProvider = StateNotifierProvider<ClubsNotifier, ClubsState>((ref) {
  return ClubsNotifier();
});
