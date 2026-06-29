import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client_type.dart';
import '../../core/network/api_service.dart';
import '../models/auth_model.dart';
import '../models/session_model.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiService _api;

  Future<void> sendOtp({
    String? email,
    String? phone,
    required OtpPurpose purpose,
  }) async {
    await _api.post(
      ApiEndpoints.sendOtp,
      client: ApiClientType.public,
      body: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'purpose': purpose.apiValue,
      },
    );
  }

  Future<AuthTokens> login({
    required String email,
    required String otp,
  }) async {
    final res = await _api.post(
      ApiEndpoints.login,
      client: ApiClientType.public,
      body: {'email': email, 'otp': otp},
    );
    return _tokensFromResponse(res);
  }

  Future<AuthTokens> signup({
    required String email,
    required String phone,
    required String otp,
    String? name,
  }) async {
    final res = await _api.post(
      ApiEndpoints.signup,
      client: ApiClientType.public,
      body: {
        'email': email,
        'phone': phone,
        'otp': otp,
        if (name != null) 'name': name,
      },
    );
    return _tokensFromResponse(res);
  }

  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    await _api.post(
      ApiEndpoints.resetPassword,
      client: ApiClientType.public,
      body: {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    await _api.post(
      ApiEndpoints.logout,
      body: {'deviceId': 'mobile'},
      authenticated: true,
    );
  }

  Future<void> logoutAll() async {
    await _api.post(ApiEndpoints.logoutAll, authenticated: true);
  }

  Future<List<SessionModel>> getSessions() async {
    final res = await _api.get(ApiEndpoints.sessions, authenticated: true);
    final list = _extractList(res);
    return list
        .whereType<Map>()
        .map((e) => SessionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> revokeSession(String deviceId) async {
    await _api.delete(
      ApiEndpoints.revokeSession(deviceId),
      authenticated: true,
    );
  }

  Future<AuthTokens> refreshTokens({required String refreshToken}) async {
    final res = await _api.post(
      ApiEndpoints.refresh,
      client: ApiClientType.public,
      body: {
        'refreshToken': refreshToken,
        'deviceId': 'mobile',
      },
    );
    return _tokensFromResponse(res);
  }

  AuthTokens _tokensFromResponse(dynamic res) {
    final map = res is Map<String, dynamic>
        ? res
        : Map<String, dynamic>.from(res as Map);
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    return AuthTokens.fromJson(data);
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    final map = res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
    final data = map['data'];
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['sessions', 'items', 'tickets', 'transactions']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    for (final key in ['sessions', 'items', 'tickets', 'transactions']) {
      if (map[key] is List) return map[key] as List;
    }
    return [];
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiServiceProvider));
});
