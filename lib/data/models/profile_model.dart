import '../../core/utils/json_parsers.dart';

class AddressModel {
  const AddressModel({
    required this.id,
    required this.label,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.addressLine2,
    this.landmark,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final double latitude;
  final double longitude;
  final bool isDefault;

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      city,
      state,
      pincode,
    ];
    return parts.join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: JsonParsers.stringValue(json['id']),
      label: JsonParsers.stringValue(json['label'], 'Home'),
      addressLine1: JsonParsers.stringValue(json['addressLine1']),
      addressLine2: json['addressLine2']?.toString(),
      city: JsonParsers.stringValue(json['city']),
      state: JsonParsers.stringValue(json['state']),
      pincode: JsonParsers.stringValue(json['pincode']),
      landmark: json['landmark']?.toString(),
      latitude: JsonParsers.doubleOrZero(json['latitude']),
      longitude: JsonParsers.doubleOrZero(json['longitude']),
      isDefault: JsonParsers.boolOr(json['isDefault']),
    );
  }
}

class ProfileModel {
  const ProfileModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.imageUrl,
    this.addresses = const [],
  });

  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? imageUrl;
  final List<AddressModel> addresses;

  factory ProfileModel.fromJson(dynamic json) {
    final map = JsonParsers.mapValue(json);
    final data = JsonParsers.mapValue(map['data']).isNotEmpty
        ? JsonParsers.mapValue(map['data'])
        : map;
    return ProfileModel(
      id: data['id']?.toString(),
      name: data['name']?.toString(),
      email: data['email']?.toString(),
      phone: data['phone']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      addresses: JsonParsers.listValue(data['addresses'])
          .whereType<Map>()
          .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
