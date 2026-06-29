import '../../core/utils/json_parsers.dart';

class OrderItemModel {
  const OrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final double price;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      name: JsonParsers.stringValue(json['name'], 'Item'),
      quantity: JsonParsers.intOr(json['quantity'], 1),
      price: JsonParsers.doubleOrZero(json['price']),
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.grandTotal,
    this.restaurantName,
    this.createdAt,
    this.items = const [],
    this.deliveryAddress,
    this.paymentMethod,
  });

  final String id;
  final String status;
  final double grandTotal;
  final String? restaurantName;
  final DateTime? createdAt;
  final List<OrderItemModel> items;
  final String? deliveryAddress;
  final String? paymentMethod;

  bool get isLive {
    const live = {
      'PLACED',
      'CONFIRMED',
      'PREPARING',
      'READY',
      'PICKED_UP',
      'ON_THE_WAY',
    };
    return live.contains(status.toUpperCase());
  }

  bool get isDelivered => status.toUpperCase() == 'DELIVERED';

  bool get isCancellable {
    const cancellable = {'PLACED', 'CONFIRMED'};
    return cancellable.contains(status.toUpperCase());
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: JsonParsers.stringValue(
        json['id'] ?? json['_id'] ?? json['orderId'],
      ),
      status: JsonParsers.stringValue(json['status'], 'PLACED'),
      grandTotal: JsonParsers.doubleOrZero(
        json['grandTotal'] ?? json['total'],
      ),
      restaurantName: json['restaurantName']?.toString() ??
          json['branch']?['name']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      items: JsonParsers.listValue(json['items'])
          .whereType<Map>()
          .map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      deliveryAddress: json['deliveryAddress']?.toString() ??
          json['address']?['addressLine1']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
    );
  }
}
