import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/cart_restaurant_cache.dart';
import '../core/utils/error_messages.dart';
import '../data/models/menu_model.dart';
import '../data/repositories/discovery_repository.dart';

class RestaurantMenuState {
  const RestaurantMenuState({
    this.restaurant,
    this.categories = const [],
    this.isLoading = true,
    this.error,
    this.searchQuery = '',
    this.vegFilter = VegFilter.all,
  });

  final RestaurantDetailModel? restaurant;
  final List<MenuCategoryModel> categories;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final VegFilter vegFilter;

  List<MenuCategoryModel> get filteredCategories {
    var cats = categories;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      cats = cats
          .map((c) {
            final items = c.items
                .where((i) =>
                    i.name.toLowerCase().contains(q) ||
                    (i.description?.toLowerCase().contains(q) ?? false))
                .toList();
            return MenuCategoryModel(
              id: c.id,
              name: c.name,
              displayName: c.displayName,
              items: items,
            );
          })
          .where((c) => c.items.isNotEmpty)
          .toList();
    }
    if (vegFilter != VegFilter.all) {
      cats = cats
          .map((c) {
            final items = c.items.where((i) {
              if (vegFilter == VegFilter.veg) return i.resolvedIsVeg == true;
              return i.resolvedIsVeg == false;
            }).toList();
            return MenuCategoryModel(
              id: c.id,
              name: c.name,
              displayName: c.displayName,
              items: items,
            );
          })
          .where((c) => c.items.isNotEmpty)
          .toList();
    }
    return cats;
  }

  RestaurantMenuState copyWith({
    RestaurantDetailModel? restaurant,
    List<MenuCategoryModel>? categories,
    bool? isLoading,
    String? error,
    String? searchQuery,
    VegFilter? vegFilter,
    bool clearError = false,
  }) {
    return RestaurantMenuState(
      restaurant: restaurant ?? this.restaurant,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      vegFilter: vegFilter ?? this.vegFilter,
    );
  }
}

enum VegFilter { all, veg, nonVeg }

class RestaurantController extends Notifier<RestaurantMenuState> {
  RestaurantController(this._branchId);

  final String _branchId;

  @override
  RestaurantMenuState build() {
    Future.microtask(() => load());
    return const RestaurantMenuState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(discoveryRepositoryProvider);
      final results = await Future.wait([
        repo.getRestaurantDetails(_branchId),
        repo.getMenu(_branchId),
      ]);
      final restaurant = results[0] as RestaurantDetailModel;
      final categories = results[1] as List<MenuCategoryModel>;
      state = state.copyWith(
        restaurant: restaurant,
        categories: categories,
        isLoading: false,
        clearError: true,
      );
      await CartRestaurantCache.save(
        name: restaurant.name,
        location: restaurant.displayLocation,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessages.userFriendly(e));
    }
  }

  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void setVegFilter(VegFilter filter) =>
      state = state.copyWith(vegFilter: filter);
}

final restaurantControllerProvider = NotifierProvider.family<
    RestaurantController, RestaurantMenuState, String>(
  RestaurantController.new,
);
