import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../data/models/cart_model.dart';
import '../data/repositories/cart_repository.dart';
import 'auth_controller.dart';

/// MVC Controller for cart state and mutations.
class CartController extends Notifier<AsyncValue<CartModel>> {
  @override
  AsyncValue<CartModel> build() {
    return AsyncValue.data(CartModel.empty);
  }

  Future<void> fetchCart() async {
    final authed = ref.read(authControllerProvider).value ?? false;
    if (!authed) {
      state = AsyncValue.data(CartModel.empty);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final cart = await ref.read(cartRepositoryProvider).getCart();
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Adds item — redirects to login if unauthenticated (matches web flow).
  Future<bool> addItem({
    required String menuItemId,
    required String branchId,
    String? returnPath,
  }) async {
    final authed = ref.read(authControllerProvider).value ?? false;
    if (!authed) {
      if (returnPath != null) {
        ref.read(authRedirectProvider.notifier).set(returnPath);
      }
      return false;
    }

    state = const AsyncValue.loading();
    try {
      final cart = await ref.read(cartRepositoryProvider).addItem(
            menuItemId: menuItemId,
            branchId: branchId,
          );
      state = AsyncValue.data(cart);
      return true;
    } on ApiException catch (e, st) {
      if (e.isUnauthorized) {
        await ref.read(authControllerProvider.notifier).logout();
        if (returnPath != null) {
          ref.read(authRedirectProvider.notifier).set(returnPath);
        }
        return false;
      }
      state = AsyncValue.error(e, st);
      rethrow;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      final cart = await ref.read(cartRepositoryProvider).updateItemQuantity(
            itemId: itemId,
            quantity: quantity,
          );
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      final cart = await ref.read(cartRepositoryProvider).removeItem(itemId);
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> applyCoupon(String code) async {
    try {
      final cart = await ref
          .read(cartRepositoryProvider)
          .applyCoupon(code.trim().toUpperCase());
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> removeCoupon() async {
    try {
      final cart = await ref.read(cartRepositoryProvider).removeCoupon();
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Clears local cart badge after successful checkout (web `setCartCount(0)`).
  void clearLocalCart() {
    state = AsyncValue.data(CartModel.empty);
  }

  int get badgeCount => state.value?.itemCount ?? 0;
}

final cartControllerProvider =
    NotifierProvider<CartController, AsyncValue<CartModel>>(CartController.new);
