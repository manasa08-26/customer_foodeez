import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/error_messages.dart';
import '../data/models/restaurant_model.dart';
import '../data/repositories/discovery_repository.dart';
import 'location_controller.dart';

class DiscoveryState {
  const DiscoveryState({
    this.restaurants = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.vegOnly = false,
    this.error,
  });

  final List<RestaurantModel> restaurants;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String searchQuery;
  final bool vegOnly;
  final String? error;

  /// Client-side veg filter for home discovery lists.
  List<RestaurantModel> get displayRestaurants {
    if (!vegOnly) return restaurants;
    return restaurants.where((r) => r.isVeg == true).toList();
  }

  DiscoveryState copyWith({
    List<RestaurantModel>? restaurants,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? searchQuery,
    bool? vegOnly,
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
      vegOnly: vegOnly ?? this.vegOnly,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// MVC Controller for restaurant discovery with pagination and search.
class DiscoveryController extends Notifier<DiscoveryState> {
  int _requestGeneration = 0;

  @override
  DiscoveryState build() {
    ref.listen(deliveryLocationProvider, (prev, next) {
      if (prev == null) return;
      if (prev.lat == next.lat && prev.lng == next.lng) return;
      Future.microtask(() => refresh());
    });
    Future.microtask(loadInitial);
    return const DiscoveryState();
  }

  DeliveryLocation _location() => ref.read(deliveryLocationProvider);

  Future<void> loadInitial() async {
    await _fetchRestaurants(
      page: 1,
      searchQuery: '',
      replace: true,
    );
  }

  Future<void> refresh() async {
    final query = state.searchQuery;
    if (query.isNotEmpty) {
      await search(query);
    } else {
      await loadInitial();
    }
  }

  void toggleVegOnly([bool? value]) {
    state = state.copyWith(vegOnly: value ?? !state.vegOnly);
  }

  Future<void> _fetchRestaurants({
    required int page,
    required String searchQuery,
    required bool replace,
  }) async {
    final generation = ++_requestGeneration;
    final trimmedQuery = searchQuery.trim();

    if (replace) {
      state = state.copyWith(
        searchQuery: trimmedQuery,
        isLoading: true,
        clearError: true,
      );
    } else {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }

    try {
      final loc = _location();
      if (generation != _requestGeneration) return;

      final repo = ref.read(discoveryRepositoryProvider);
      final result = trimmedQuery.isNotEmpty
          ? await repo.search(
              query: trimmedQuery,
              lat: loc.lat,
              lng: loc.lng,
              page: page,
            )
          : await repo.getNearby(
              lat: loc.lat,
              lng: loc.lng,
              page: page,
            );

      if (generation != _requestGeneration) return;

      if (replace) {
        state = DiscoveryState(
          restaurants: result.items,
          page: page,
          hasMore: result.hasMore,
          searchQuery: trimmedQuery,
          vegOnly: state.vegOnly,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          restaurants: [...state.restaurants, ...result.items],
          page: page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        );
      }
    } catch (e) {
      if (generation != _requestGeneration) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: ErrorMessages.userFriendly(e),
      );
    }
  }

  Future<void> search(String query) async {
    await _fetchRestaurants(
      page: 1,
      searchQuery: query,
      replace: true,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    await _fetchRestaurants(
      page: state.page + 1,
      searchQuery: state.searchQuery,
      replace: false,
    );
  }
}

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryState>(
  DiscoveryController.new,
);
