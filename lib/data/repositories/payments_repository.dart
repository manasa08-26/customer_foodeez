import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/json_parsers.dart';
import '../models/wallet_model.dart';

class PaymentsRepository {
  PaymentsRepository(this._api);

  final ApiService _api;

  Future<WalletModel> getWallet() async {
    final res = await _api.get(ApiEndpoints.wallet, authenticated: true);
    return WalletModel.fromJson(res);
  }

  Future<List<WalletTransactionModel>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(
      ApiEndpoints.walletTransactions,
      authenticated: true,
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final list = _extractList(res);
    return list
        .whereType<Map>()
        .map((e) => WalletTransactionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> topUpInitiate({
    required double amount,
    String gateway = 'razorpay',
  }) async {
    await _api.post(
      ApiEndpoints.walletTopupInitiate,
      authenticated: true,
      body: {'amount': amount, 'gateway': gateway},
    );
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    final map = JsonParsers.mapValue(res);
    final data = JsonParsers.mapValue(map['data']);
    if (data['transactions'] is List) return data['transactions'] as List;
    if (data['items'] is List) return data['items'] as List;
    if (map['transactions'] is List) return map['transactions'] as List;
    return [];
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(apiServiceProvider));
});
