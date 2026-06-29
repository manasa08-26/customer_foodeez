import '../../core/utils/json_parsers.dart';

class RestaurantModel {
  const RestaurantModel({
    required this.id,
    required this.branchId,
    required this.name,
    this.cuisine,
    this.rating,
    this.deliveryTime,
    this.deliveryFee,
    this.imageUrl,
    this.isVeg,
    this.distance,
  });

  final String id;
  final String branchId;
  final String name;
  final String? cuisine;
  final double? rating;
  final int? deliveryTime;
  final double? deliveryFee;
  final String? imageUrl;
  final bool? isVeg;
  final double? distance;

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: JsonParsers.stringValue(
        json['id'] ?? json['_id'] ?? json['branchId'],
      ),
      branchId: JsonParsers.stringValue(
        json['branchId'] ?? json['id'] ?? json['_id'],
      ),
      name: JsonParsers.stringValue(json['name'], 'Restaurant'),
      cuisine: json['cuisine']?.toString(),
      rating: JsonParsers.doubleValue(json['rating']),
      deliveryTime: JsonParsers.intValue(json['deliveryTime']),
      deliveryFee: JsonParsers.doubleValue(json['deliveryFee']),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      isVeg: JsonParsers.boolValue(json['isVeg']),
      distance: JsonParsers.doubleValue(json['distance']),
    );
  }
}
