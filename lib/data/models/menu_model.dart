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

  /// Parses veg flag from API — supports camelCase, snake_case, and foodType.
  static bool? parseIsVeg(Map<String, dynamic> json) {
    final direct = JsonParsers.boolValue(
      json['isVeg'] ?? json['is_veg'] ?? json['veg'],
    );
    if (direct != null) return direct;

    final foodType =
        json['foodType'] ?? json['food_type'] ?? json['itemType'] ?? json['type'];
    if (foodType != null) {
      final normalized = foodType.toString().trim().toUpperCase();
      if (normalized.contains('NON')) return false;
      if (normalized.contains('VEG')) return true;
    }
    return null;
  }

  /// Veg flag from API, or inferred from item name when the API omits it.
  bool? get resolvedIsVeg => isVeg ?? inferVegFromName(name);

  static bool? inferVegFromName(String name) {
    final n = name.toLowerCase();
    const nonVegTerms = [
      'chicken', 'mutton', 'lamb', 'prawn', 'prawns', 'fish', 'egg', 'eggs',
      'meat', 'keema', 'kheema', 'beef', 'pork', 'crab', 'seafood', 'goat',
      'liver', 'gizzard', 'nalli', 'boneless fry', 'duck', 'turkey', 'ham',
    ];
    for (final term in nonVegTerms) {
      if (n.contains(term)) return false;
    }
    const vegTerms = [
      'paneer', 'veg ', 'veg-', 'vegetable', 'aloo', 'gobi', 'mushroom',
      'dal', 'chana', 'palak', 'corn', 'capsicum', 'tomato', 'manchuria',
      'fry piece', 'samosa', 'dosa', 'idli', 'vada', 'poori', 'roti',
    ];
    for (final term in vegTerms) {
      if (n.contains(term)) return true;
    }
    return null;
  }

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: JsonParsers.stringValue(json['id']),
      name: JsonParsers.stringValue(json['name']),
      price: JsonParsers.doubleOrZero(json['price']),
      description: json['description']?.toString(),
      isVeg: MenuItemModel.parseIsVeg(json),
      imageUrl: (json['imageUrl'] ?? json['image_url'])?.toString(),
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
      items: JsonParsers.listValue(json['items'] ?? json['menuItems'])
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
    this.location,
    this.city,
  });

  final String name;
  final String? cuisine;
  final double? rating;
  final int? deliveryTime;
  final double? deliveryFee;
  final String? imageUrl;
  final String? location;
  final String? city;

  String get displayLocation => location ?? city ?? '';

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
      location: data['location']?.toString(),
      city: data['city']?.toString(),
    );
  }
}
