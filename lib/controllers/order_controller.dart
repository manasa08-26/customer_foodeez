import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/error_messages.dart';
import '../data/models/order_model.dart';
import '../data/repositories/order_repository.dart';

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isLoading = true,
    this.error,
    this.filter = OrderFilter.all,
  });

  final List<OrderModel> orders;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isLoading;
  final String? error;
  final OrderFilter filter;

  List<OrderModel> get filteredOrders {
    return switch (filter) {
      OrderFilter.live => orders.where((o) => o.isLive).toList(),
      OrderFilter.past => orders.where((o) => !o.isLive).toList(),
      OrderFilter.all => orders,
    };
  }

  OrdersState copyWith({
    List<OrderModel>? orders,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isLoading,
    String? error,
    OrderFilter? filter,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
    );
  }
}

enum OrderFilter { all, live, past }

class OrderController extends Notifier<OrdersState> {
  @override
  OrdersState build() {
    Future.microtask(loadOrders);
    return const OrdersState();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result =
          await ref.read(orderRepositoryProvider).getOrders(page: 1);
      state = OrdersState(
        orders: result.items,
        page: 1,
        hasMore: result.hasMore,
        isLoading: false,
        filter: state.filter,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessages.userFriendly(e));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = state.page + 1;
      final result =
          await ref.read(orderRepositoryProvider).getOrders(page: next);
      state = state.copyWith(
        orders: [...state.orders, ...result.items],
        page: next,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: ErrorMessages.userFriendly(e));
    }
  }

  void setFilter(OrderFilter filter) =>
      state = state.copyWith(filter: filter);

  Future<OrderModel> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? instructions,
  }) async {
    return ref.read(orderRepositoryProvider).placeOrder(
          deliveryAddressId: addressId,
          paymentMethod: paymentMethod,
          specialInstructions: instructions,
        );
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await ref.read(orderRepositoryProvider).cancelOrder(orderId, reason);
  }

  Future<void> reorder(String orderId) async {
    await ref.read(orderRepositoryProvider).reorder(orderId);
  }
}

final orderControllerProvider =
    NotifierProvider<OrderController, OrdersState>(OrderController.new);

final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, orderId) async {
  return ref.read(orderRepositoryProvider).getOrder(orderId);
});
