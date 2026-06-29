import '../../core/utils/json_parsers.dart';

class CartItemModel {
  CartItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.itemTotal,
    this.imageUrl,
    this.isVeg,
    this.specialNote,
  });

  final String id;
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double? itemTotal;
  final String? imageUrl;
  final bool? isVeg;
  final String? specialNote;

  double get lineTotal => itemTotal ?? (unitPrice * quantity);

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final menuItem = JsonParsers.mapValue(json['menuItem']);
    final hasMenuItem = menuItem.isNotEmpty;
    return CartItemModel(
      id: JsonParsers.stringValue(json['id']),
      menuItemId: JsonParsers.stringValue(
        json['menuItemId'] ?? (hasMenuItem ? menuItem['id'] : null),
      ),
      name: JsonParsers.stringValue(
        json['menuItemName'] ??
            json['name'] ??
            (hasMenuItem ? menuItem['name'] : null),
        'Item',
      ),
      quantity: JsonParsers.intOr(json['quantity'], 1),
      unitPrice: JsonParsers.doubleOrZero(
        json['unitPrice'] ?? json['price'] ?? menuItem['price'],
      ),
      itemTotal: json['itemTotal'] != null
          ? JsonParsers.doubleOrZero(json['itemTotal'])
          : null,
      imageUrl: menuItem['imageUrl']?.toString(),
      isVeg: JsonParsers.boolValue(menuItem['isVeg']),
      specialNote: json['specialNote']?.toString(),
    );
  }
}

class CartModel {
  CartModel({
    required this.items,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.packagingFee = 0,
    this.taxAmount = 0,
    this.surgeFee = 0,
    this.discountAmount = 0,
    this.couponDiscount = 0,
    this.grandTotal = 0,
    this.couponCode,
    this.branchId,
    this.restaurantName,
    this.restaurantLocation,
  });

  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double packagingFee;
  final double taxAmount;
  final double surgeFee;
  final double discountAmount;
  final double couponDiscount;
  final double grandTotal;
  final String? couponCode;
  final String? branchId;
  final String? restaurantName;
  final String? restaurantLocation;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  bool get isEmpty => items.isEmpty;

  double get effectiveCouponDiscount =>
      couponDiscount > 0 ? couponDiscount : discountAmount;

  factory CartModel.fromJson(dynamic json) {
    final map = JsonParsers.mapValue(json);
    final data = JsonParsers.mapValue(map['data']).isNotEmpty
        ? JsonParsers.mapValue(map['data'])
        : map;

    final items = JsonParsers.listValue(data['items'])
        .whereType<Map>()
        .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final couponDiscount = JsonParsers.doubleOrZero(data['couponDiscount']);

    return CartModel(
      items: items,
      subtotal: JsonParsers.doubleOrZero(data['subtotal']),
      deliveryFee: JsonParsers.doubleOrZero(data['deliveryFee']),
      packagingFee: JsonParsers.doubleOrZero(data['packagingFee']),
      taxAmount: JsonParsers.doubleOrZero(data['taxAmount']),
      surgeFee: JsonParsers.doubleOrZero(data['surgeFee']),
      discountAmount: JsonParsers.doubleOrZero(data['discountAmount']),
      couponDiscount: couponDiscount,
      grandTotal: JsonParsers.doubleOrZero(data['grandTotal']),
      couponCode: data['appliedCouponCode']?.toString() ??
          data['couponCode']?.toString(),
      branchId: data['branchId']?.toString(),
      restaurantName: data['restaurantName']?.toString(),
      restaurantLocation: data['restaurantLocation']?.toString(),
    );
  }

  static final empty = CartModel(items: []);
}
