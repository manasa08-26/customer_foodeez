import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/json_parsers.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiService _api;

  Future<ProfileModel> getProfile() async {
    final res = await _api.get(ApiEndpoints.profile, authenticated: true);
    return ProfileModel.fromJson(res);
  }

  Future<List<AddressModel>> getAddresses() async {
    final res = await _api.get(ApiEndpoints.addresses, authenticated: true);
    final list = _extractList(res);
    return list
        .whereType<Map>()
        .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ProfileModel> updateProfile({
    String? name,
    String? email,
    String? dateOfBirth,
  }) async {
    final res = await _api.patch(
      ApiEndpoints.profile,
      authenticated: true,
      body: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      },
    );
    return ProfileModel.fromJson(res);
  }

  Future<AddressModel> addAddress({
    required String label,
    required String addressLine1,
    required String city,
    required String state,
    required String pincode,
    String? addressLine2,
    String? landmark,
    bool isDefault = false,
  }) async {
    final res = await _api.post(
      ApiEndpoints.addresses,
      authenticated: true,
      body: {
        'label': label,
        'addressLine1': addressLine1,
        if (addressLine2 != null) 'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'pincode': pincode,
        if (landmark != null) 'landmark': landmark,
        'latitude': 0,
        'longitude': 0,
        'isDefault': isDefault,
      },
    );
    final map = JsonParsers.mapValue(res);
    final data = JsonParsers.mapValue(map['data']).isNotEmpty
        ? JsonParsers.mapValue(map['data'])
        : map;
    return AddressModel.fromJson(data);
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete(ApiEndpoints.address(id), authenticated: true);
  }

  Future<void> setDefaultAddress(String id) async {
    await _api.patch(ApiEndpoints.addressDefault(id), authenticated: true);
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    final map = JsonParsers.mapValue(res);
    final data = JsonParsers.mapValue(map['data']);
    if (data['addresses'] is List) return data['addresses'] as List;
    if (data['items'] is List) return data['items'] as List;
    if (map['addresses'] is List) return map['addresses'] as List;
    return [];
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiServiceProvider));
});
