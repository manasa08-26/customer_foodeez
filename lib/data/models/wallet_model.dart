import '../../core/utils/json_parsers.dart';

class WalletModel {
  const WalletModel({
    required this.balance,
    this.currency = 'INR',
  });

  final double balance;
  final String currency;

  factory WalletModel.fromJson(dynamic json) {
    final map = JsonParsers.mapValue(json);
    final data = JsonParsers.mapValue(map['data']).isNotEmpty
        ? JsonParsers.mapValue(map['data'])
        : map;
    final wallet = JsonParsers.mapValue(data['wallet']);
    final source = wallet.isNotEmpty ? wallet : data;
    return WalletModel(
      balance: JsonParsers.doubleOrZero(
        source['balance'] ?? source['walletBalance'],
      ),
      currency: JsonParsers.stringValue(source['currency'], 'INR'),
    );
  }
}

class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    this.description,
    this.createdAt,
    this.status,
  });

  final String id;
  final double amount;
  final String type;
  final String? description;
  final DateTime? createdAt;
  final String? status;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: JsonParsers.stringValue(json['id']),
      amount: JsonParsers.doubleOrZero(json['amount']),
      type: JsonParsers.stringValue(json['type'] ?? json['transactionType']),
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(
        JsonParsers.stringValue(json['createdAt']),
      ),
      status: json['status']?.toString(),
    );
  }
}
