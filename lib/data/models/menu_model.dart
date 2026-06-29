import '../../core/utils/json_parsers.dart';

class MenuAddonModel {
  const MenuAddonModel({
    required this.id,
    required this.name,
    required this.price,
    this.isRequired = false,
  });

  final String id;
  final String name;
  final double price;
  final bool isRequired;

  factory MenuAddonModel.fromJson(Map<String, dynamic> json) {
    return MenuAddonModel(
      id: JsonParsers.stringValue(json['id']),
      name: JsonParsers.stringValue(json['name']),
      price: JsonParsers.doubleOrZero(json['price']),
      isRequired: JsonParsers.boolOr(json['isRequired']),
    );
  }
}

class MenuItemModel {
  const MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.isVeg,
    this.imageUrl,
    this.addons = const [],
  });

  final String id;
  final String name;
  final double price;
  final String? description;
  final bool? isVeg;
  final String? imageUrl;
  final List<MenuAddonModel> addons;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: JsonParsers.stringValue(json['id']),
      name: JsonParsers.stringValue(json['name']),
      price: JsonParsers.doubleOrZero(json['price']),
      description: json['description']?.toString(),
      isVeg: JsonParsers.boolValue(json['isVeg']),
      imageUrl: json['imageUrl']?.toString(),
      addons: JsonParsers.listValue(json['addons'])
          .whereType<Map>()
          .map((e) => MenuAddonModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class MenuCategoryModel {
  const MenuCategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.items,
  });

  final String id;
  final String name;
  final String displayName;
  final List<MenuItemModel> items;

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      id: JsonParsers.stringValue(json['id']),
      name: JsonParsers.stringValue(json['name']),
      displayName: JsonParsers.stringValue(
        json['displayName'] ?? json['name'],
      ),
      items: JsonParsers.listValue(json['items'])
          .whereType<Map>()
          .map((e) => MenuItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class RestaurantDetailModel {
  const RestaurantDetailModel({
    required this.name,
    this.cuisine,
    this.rating,
    this.deliveryTime,
    this.deliveryFee,
    this.imageUrl,
  });

  final String name;
  final String? cuisine;
  final double? rating;
  final int? deliveryTime;
  final double? deliveryFee;
  final String? imageUrl;

  factory RestaurantDetailModel.fromJson(Map<String, dynamic> json) {
    final data = JsonParsers.mapValue(json['data']).isNotEmpty
        ? JsonParsers.mapValue(json['data'])
        : json;
    return RestaurantDetailModel(
      name: JsonParsers.stringValue(data['name'], 'Restaurant'),
      cuisine: data['cuisine']?.toString(),
      rating: JsonParsers.doubleValue(data['rating']),
      deliveryTime: JsonParsers.intValue(data['deliveryTime']),
      deliveryFee: JsonParsers.doubleValue(data['deliveryFee']),
      imageUrl: data['imageUrl']?.toString(),
    );
  }
}
