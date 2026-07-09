import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../models/order_model.dart';
import '../models/paginated_response.dart';

/// Repository for order placement and history.
class OrderRepository {
  OrderRepository(this._api);

  final ApiService _api;

  Future<OrderModel> placeOrder({
    required String deliveryAddressId,
    required String paymentMethod,
    String? specialInstructions,
  }) async {
    final res = await _api.post(
      ApiEndpoints.orders,
      authenticated: true,
      body: {
        'deliveryAddressId': deliveryAddressId,
        'paymentMethod': paymentMethod,
        if (specialInstructions != null)
          'specialInstructions': specialInstructions,
      },
    );
    final map = res is Map<String, dynamic>
        ? res
        : Map<String, dynamic>.from(res as Map);
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    return OrderModel.fromJson(data);
  }

  Future<PaginatedResponse<OrderModel>> getOrders({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await _api.get(
      ApiEndpoints.orders,
      authenticated: true,
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return PaginatedResponse.fromJson(res, OrderModel.fromJson, itemsKey: 'orders');
  }

  Future<OrderModel> getOrder(String orderId) async {
    final res = await _api.get(
      ApiEndpoints.order(orderId),
      authenticated: true,
    );
    final map = res is Map<String, dynamic>
        ? res
        : Map<String, dynamic>.from(res as Map);
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    return OrderModel.fromJson(data);
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await _api.post(
      ApiEndpoints.orderCancel(orderId),
      authenticated: true,
      body: {'reason': reason},
    );
  }

  Future<void> reorder(String orderId) async {
    await _api.post(
      ApiEndpoints.orderReorder(orderId),
      authenticated: true,
    );
  }

  Future<Map<String, dynamic>> getTracking(String orderId) async {
    final res = await _api.get(
      ApiEndpoints.orderTracking(orderId),
      authenticated: true,
    );
    if (res is Map<String, dynamic>) return res;
    return Map<String, dynamic>.from(res as Map);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiServiceProvider));
});
