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
    return WalletModel(
      balance: JsonParsers.doubleOrZero(
        data['balance'] ?? data['walletBalance'],
      ),
      currency: JsonParsers.stringValue(data['currency'], 'INR'),
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
  });

  final String id;
  final double amount;
  final String type;
  final String? description;
  final DateTime? createdAt;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: JsonParsers.stringValue(json['id']),
      amount: JsonParsers.doubleOrZero(json['amount']),
      type: JsonParsers.stringValue(json['type'] ?? json['transactionType']),
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(
        JsonParsers.stringValue(json['createdAt']),
      ),
    );
  }
}
