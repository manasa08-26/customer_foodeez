import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/utils/error_messages.dart';
import '../data/models/restaurant_model.dart';
import '../data/repositories/discovery_repository.dart';

/// Cached coordinates for discovery API calls.
class LocationState {
  const LocationState({required this.lat, required this.lng});

  final double lat;
  final double lng;

  static const fallback = LocationState(lat: 17.385, lng: 78.4867);
}

/// Resolves GPS quickly — last-known first, then low-accuracy with 2s cap.
final locationResolverProvider = Provider<LocationResolver>((ref) {
  return LocationResolver();
});

class LocationResolver {
  LocationState? _cached;

  LocationState get cached => _cached ?? LocationState.fallback;

  Future<LocationState> resolve({Duration timeout = const Duration(seconds: 2)}) async {
    if (_cached != null) return _cached!;

    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _cached = LocationState(lat: last.latitude, lng: last.longitude);
        return _cached!;
      }
    } catch (_) {}

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeout,
        ),
      ).timeout(timeout);
      _cached = LocationState(lat: pos.latitude, lng: pos.longitude);
      return _cached!;
    } catch (_) {
      _cached = LocationState.fallback;
      return _cached!;
    }
  }
}

class DiscoveryState {
  const DiscoveryState({
    this.restaurants = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.error,
  });

  final List<RestaurantModel> restaurants;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String searchQuery;
  final String? error;

  DiscoveryState copyWith({
    List<RestaurantModel>? restaurants,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? searchQuery,
    String? error,
    bool clearError = false,
  }) {
    return DiscoveryState(
      restaurants: restaurants ?? this.restaurants,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// MVC Controller for restaurant discovery with pagination and search.
class DiscoveryController extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() {
    Future.microtask(loadInitial);
    return const DiscoveryState();
  }

  Future<LocationState> _location() async {
    return ref.read(locationResolverProvider).resolve();
  }

  Future<void> loadInitial() async {
    if (state.isLoading && state.restaurants.isEmpty) {
      state = state.copyWith(clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final loc = await _location();
      final result = await ref.read(discoveryRepositoryProvider).getNearby(
            lat: loc.lat,
            lng: loc.lng,
            page: 1,
          );
      state = DiscoveryState(
        restaurants: result.items,
        page: 1,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorMessages.userFriendly(e),
      );
    }
  }

  Future<void> refresh() => loadInitial();

  Future<void> search(String query) async {
    state = state.copyWith(
      searchQuery: query,
      isLoading: true,
      clearError: true,
    );
    if (query.trim().isEmpty) {
      await loadInitial();
      return;
    }
    try {
      final loc = await _location();
      final result = await ref.read(discoveryRepositoryProvider).search(
            query: query.trim(),
            lat: loc.lat,
            lng: loc.lng,
          );
      state = DiscoveryState(
        restaurants: result.items,
        page: 1,
        hasMore: result.hasMore,
        searchQuery: query,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorMessages.userFriendly(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final loc = await _location();
      final nextPage = state.page + 1;
      final repo = ref.read(discoveryRepositoryProvider);
      final result = state.searchQuery.isNotEmpty
          ? await repo.search(
              query: state.searchQuery,
              lat: loc.lat,
              lng: loc.lng,
              page: nextPage,
            )
          : await repo.getNearby(
              lat: loc.lat,
              lng: loc.lng,
              page: nextPage,
            );
      state = state.copyWith(
        restaurants: [...state.restaurants, ...result.items],
        page: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: ErrorMessages.userFriendly(e),
      );
    }
  }
}

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryState>(
  DiscoveryController.new,
);
