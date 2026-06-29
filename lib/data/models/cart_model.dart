import '../../core/utils/json_parsers.dart';

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
    this.isVeg,
    this.specialNote,
  });

  final String id;
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;
  final bool? isVeg;
  final String? specialNote;

  double get lineTotal => unitPrice * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final menuItem = JsonParsers.mapValue(json['menuItem']);
    final hasMenuItem = menuItem.isNotEmpty;
    return CartItemModel(
      id: JsonParsers.stringValue(json['id']),
      menuItemId: JsonParsers.stringValue(
        json['menuItemId'] ?? (hasMenuItem ? menuItem['id'] : null),
      ),
      name: JsonParsers.stringValue(
        json['name'] ?? (hasMenuItem ? menuItem['name'] : null),
        'Item',
      ),
      quantity: JsonParsers.intOr(json['quantity'], 1),
      unitPrice: JsonParsers.doubleOrZero(
        json['unitPrice'] ?? json['price'] ?? menuItem['price'],
      ),
      imageUrl: menuItem['imageUrl']?.toString(),
      isVeg: JsonParsers.boolValue(menuItem['isVeg']),
      specialNote: json['specialNote']?.toString(),
    );
  }
}

class CartModel {
  const CartModel({
    required this.items,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.grandTotal = 0,
    this.couponCode,
    this.branchId,
  });

  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double discountAmount;
  final double grandTotal;
  final String? couponCode;
  final String? branchId;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  bool get isEmpty => items.isEmpty;

  factory CartModel.fromJson(dynamic json) {
    final map = JsonParsers.mapValue(json);
    final data = JsonParsers.mapValue(map['data']).isNotEmpty
        ? JsonParsers.mapValue(map['data'])
        : map;

    final items = JsonParsers.listValue(data['items'])
        .whereType<Map>()
        .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return CartModel(
      items: items,
      subtotal: JsonParsers.doubleOrZero(data['subtotal']),
      deliveryFee: JsonParsers.doubleOrZero(data['deliveryFee']),
      taxAmount: JsonParsers.doubleOrZero(data['taxAmount']),
      discountAmount: JsonParsers.doubleOrZero(data['discountAmount']),
      grandTotal: JsonParsers.doubleOrZero(data['grandTotal']),
      couponCode: data['couponCode']?.toString(),
      branchId: data['branchId']?.toString(),
    );
  }

  static const empty = CartModel(items: []);
}
