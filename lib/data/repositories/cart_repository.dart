import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../models/cart_model.dart';

/// Repository for cart operations.
class CartRepository {
  CartRepository(this._api);

  final ApiService _api;

  Future<CartModel> getCart() async {
    final res = await _api.get(ApiEndpoints.cart, authenticated: true);
    return CartModel.fromJson(res);
  }

  Future<CartModel> addItem({
    required String menuItemId,
    required String branchId,
    int quantity = 1,
    String? specialNote,
  }) async {
    final res = await _api.post(
      ApiEndpoints.cartItems,
      authenticated: true,
      body: {
        'menuItemId': menuItemId,
        'branchId': branchId,
        'quantity': quantity,
        if (specialNote != null) 'specialNote': specialNote,
      },
    );
    return CartModel.fromJson(res);
  }

  Future<CartModel> updateItemQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final res = await _api.patch(
      ApiEndpoints.cartItem(itemId),
      authenticated: true,
      body: {'quantity': quantity},
    );
    return CartModel.fromJson(res);
  }

  Future<CartModel> removeItem(String itemId) async {
    final res = await _api.delete(
      ApiEndpoints.cartItem(itemId),
      authenticated: true,
    );
    return CartModel.fromJson(res ?? {'items': []});
  }

  Future<CartModel> clearCart() async {
    await _api.delete(ApiEndpoints.cart, authenticated: true);
    return CartModel.empty;
  }

  Future<CartModel> applyCoupon(String couponCode) async {
    final res = await _api.post(
      ApiEndpoints.cartCoupon,
      authenticated: true,
      body: {'couponCode': couponCode},
    );
    return CartModel.fromJson(res);
  }

  Future<CartModel> removeCoupon() async {
    final res = await _api.delete(ApiEndpoints.cartCoupon, authenticated: true);
    return CartModel.fromJson(res ?? {'items': []});
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(apiServiceProvider));
});
