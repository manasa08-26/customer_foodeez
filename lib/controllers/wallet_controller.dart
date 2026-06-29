import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/wallet_model.dart';
import '../data/repositories/payments_repository.dart';

final walletControllerProvider =
    AsyncNotifierProvider<WalletController, WalletState>(WalletController.new);

class WalletState {
  const WalletState({
    this.wallet,
    this.transactions = const [],
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final WalletModel? wallet;
  final List<WalletTransactionModel> transactions;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  WalletState copyWith({
    WalletModel? wallet,
    List<WalletTransactionModel>? transactions,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  double get totalSpent => transactions
      .where((t) => t.type == 'DEBIT')
      .fold(0, (sum, t) => sum + t.amount);

  double get totalCashback => transactions
      .where((t) =>
          t.type.contains('REFUND') || t.type.contains('CASHBACK'))
      .fold(0, (sum, t) => sum + t.amount);
}

class WalletController extends AsyncNotifier<WalletState> {
  static const _pageSize = 20;

  @override
  Future<WalletState> build() async => _load(page: 1);

  Future<WalletState> _load({required int page}) async {
    final repo = ref.read(paymentsRepositoryProvider);
    final wallet = await repo.getWallet();
    final transactions = await repo.getTransactions(page: page, limit: _pageSize);
    return WalletState(
      wallet: wallet,
      transactions: transactions,
      page: page,
      hasMore: transactions.length == _pageSize,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(page: 1));
  }

  Future<String?> topUp(
    double amount, {
    String gateway = 'razorpay',
  }) async {
    final res = await ref.read(paymentsRepositoryProvider).topUpInitiate(
          amount: amount,
          gateway: gateway,
        );
    await refresh();
    final id = res['orderId']?.toString() ?? res['id']?.toString();
    return id;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final more = await ref.read(paymentsRepositoryProvider).getTransactions(
            page: nextPage,
            limit: _pageSize,
          );
      state = AsyncValue.data(
        current.copyWith(
          transactions: [...current.transactions, ...more],
          page: nextPage,
          hasMore: more.length == _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }
}
