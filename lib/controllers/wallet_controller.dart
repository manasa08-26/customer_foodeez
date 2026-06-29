import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/wallet_model.dart';
import '../data/repositories/payments_repository.dart';

final walletControllerProvider =
    AsyncNotifierProvider<WalletController, WalletState>(WalletController.new);

class WalletState {
  const WalletState({
    this.wallet,
    this.transactions = const [],
    this.isLoadingMore = false,
  });

  final WalletModel? wallet;
  final List<WalletTransactionModel> transactions;
  final bool isLoadingMore;

  WalletState copyWith({
    WalletModel? wallet,
    List<WalletTransactionModel>? transactions,
    bool? isLoadingMore,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class WalletController extends AsyncNotifier<WalletState> {
  @override
  Future<WalletState> build() async => _load();

  Future<WalletState> _load() async {
    final repo = ref.read(paymentsRepositoryProvider);
    final wallet = await repo.getWallet();
    final transactions = await repo.getTransactions();
    return WalletState(wallet: wallet, transactions: transactions);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> topUp(double amount) async {
    await ref.read(paymentsRepositoryProvider).topUpInitiate(amount: amount);
    await refresh();
  }
}
