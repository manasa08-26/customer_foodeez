import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../models/menu_model.dart';
import '../models/paginated_response.dart';
import '../models/restaurant_model.dart';

/// Repository for restaurant discovery and menu APIs.
class DiscoveryRepository {
  DiscoveryRepository(this._api);

  final ApiService _api;

  Future<PaginatedResponse<RestaurantModel>> getNearby({
    required double lat,
    required double lng,
    int radius = 50000,
    int page = 1,
    int limit = 20,
    String? cuisine,
    String? sortBy,
  }) async {
    final res = await _api.get(
      ApiEndpoints.discoveryNearby,
      query: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radius.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
        if (cuisine != null) 'cuisine': cuisine,
        if (sortBy != null) 'sortBy': sortBy,
      },
    );
    return PaginatedResponse.fromJson(
      res,
      RestaurantModel.fromJson,
      itemsKey: 'restaurants',
    );
  }

  Future<PaginatedResponse<RestaurantModel>> search({
    required String query,
    required double lat,
    required double lng,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(
      ApiEndpoints.discoverySearch,
      query: {
        'q': query,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return PaginatedResponse.fromJson(
      res,
      RestaurantModel.fromJson,
      itemsKey: 'restaurants',
    );
  }

  Future<RestaurantDetailModel> getRestaurantDetails(String branchId) async {
    final res = await _api.get(ApiEndpoints.restaurantDetails(branchId));
    final map = res is Map<String, dynamic>
        ? res
        : Map<String, dynamic>.from(res as Map);
    return RestaurantDetailModel.fromJson(map);
  }

  Future<List<MenuCategoryModel>> getMenu(String branchId) async {
    final res = await _api.get(ApiEndpoints.restaurantMenu(branchId));
    final map = res is Map<String, dynamic>
        ? res
        : res is Map
            ? Map<String, dynamic>.from(res)
            : <String, dynamic>{};

    final categories = map['categories'] as List? ??
        map['data']?['categories'] as List? ??
        (res is List ? res : null) ??
        [];

    return categories
        .whereType<Map>()
        .map((e) => MenuCategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<RestaurantModel>> getTrending({
    required double lat,
    required double lng,
  }) async {
    final res = await _api.get(
      ApiEndpoints.discoveryTrending,
      query: {
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );
    return _parseRestaurantList(res);
  }

  Future<List<dynamic>> getPopularDishes({
    required double lat,
    required double lng,
  }) async {
    final res = await _api.get(
      ApiEndpoints.discoveryPopularDishes,
      query: {
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );
    final map = res is Map<String, dynamic>
        ? res
        : Map<String, dynamic>.from(res as Map);
    return map['dishes'] as List? ??
        map['data']?['dishes'] as List? ??
        (res is List ? res : <dynamic>[]);
  }

  List<RestaurantModel> _parseRestaurantList(dynamic res) {
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => RestaurantModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final map = res is Map<String, dynamic>
        ? res
        : Map<String, dynamic>.from(res as Map);
    final list = map['restaurants'] as List? ??
        map['data']?['restaurants'] as List? ??
        map['items'] as List? ??
        [];
    return list
        .whereType<Map>()
        .map((e) => RestaurantModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(ref.watch(apiServiceProvider));
});
