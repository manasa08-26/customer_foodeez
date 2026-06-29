import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants/api_endpoints.dart';
import '../constants/env.dart';
import '../storage/token_storage.dart';
import '../../controllers/auth_controller.dart';
import 'api_client_type.dart';
import 'api_exception.dart';
import 'api_http_client.dart';

/// Low-level HTTP client — all network calls go through this layer.
class ApiService {
  ApiService(this._tokenStorage, this._client);

  final TokenStorage _tokenStorage;
  final http.Client _client;
  static const _timeout = Duration(seconds: 30);
  static const _maxAttempts = 3;

  /// Called when refresh fails — wire to logout in [apiServiceProvider].
  Future<void> Function()? onSessionExpired;

  bool _refreshing = false;

  String _baseUrl(ApiClientType type) {
    return switch (type) {
      ApiClientType.public => Env.apiBaseUrl,
      ApiClientType.customer => Env.customerApiBaseUrl,
    };
  }

  Future<Map<String, String>> _headers({
    required ApiClientType client,
    bool authenticated = false,
    Map<String, String>? extra,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?extra,
    };

    if (authenticated) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _uri(ApiClientType client, String path, [Map<String, String>? query]) {
    final base = _baseUrl(client);
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized').replace(queryParameters: query);
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  String _extractMessage(dynamic body, int statusCode) {
    if (body is Map) {
      final msg = body['message'] ?? body['error'] ?? body['msg'];
      if (msg != null) return msg.toString();
    }
    return 'Request failed with status $statusCode';
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = _decodeBody(response);
    throw ApiException(
      message: _extractMessage(body, response.statusCode),
      statusCode: response.statusCode,
      body: body,
    );
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final uri = _uri(ApiClientType.public, ApiEndpoints.refresh);
      final response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'refreshToken': refreshToken,
              'deviceId': 'mobile',
            }),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final body = _decodeBody(response);
      final map = body is Map<String, dynamic>
          ? body
          : Map<String, dynamic>.from(body as Map);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      final access = data['accessToken']?.toString();
      final refresh = data['refreshToken']?.toString();
      if (access == null || access.isEmpty || refresh == null) return false;

      await _tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _handleUnauthorized() async {
    await onSessionExpired?.call();
  }

  bool _isRetryable(Object error) {
    if (error is ApiException) return false;
    return error is SocketException ||
        error is TimeoutException ||
        error is HandshakeException ||
        error is TlsException ||
        error is http.ClientException;
  }

  bool _isTimeoutError(Object error) {
    if (error is TimeoutException) return true;
    final text = error.toString().toLowerCase();
    return text.contains('timed out') || text.contains('timeout');
  }

  String _androidEmulatorHint() {
    if (!Platform.isAndroid) return '';
    return ' On Android emulator: open Chrome and visit https://int.foodeez.in. '
        'If that fails, the emulator has no internet — use a physical device, '
        'cold-boot the emulator, or run against local backend '
        '(API_BASE_URL=http://10.0.2.2:4004/api/v1).';
  }

  String _timeoutMessage(Uri uri) {
    if (Env.isProductionHost) {
      return 'Connection timed out reaching Foodeez. '
          'Check your internet connection and try again.'
          '${_androidEmulatorHint()}';
    }
    return 'Connection timed out reaching ${uri.host}. '
        'Ensure the local backend is running on port 4004.';
  }

  String _connectionMessage(Uri uri) {
    if (Env.isProductionHost) {
      return 'Cannot reach Foodeez servers (${uri.host}). '
          'Check your internet connection, turn off VPN if enabled, and try again.'
          '${_androidEmulatorHint()}';
    }
    return 'Cannot connect to ${uri.host}:${uri.port}. '
        'Start the backend with npm run start:customer:dev '
        '(Android emulator: API_BASE_URL=http://10.0.2.2:4004/api/v1).';
  }

  Never _rethrowAsApiException(Object error, String method, Uri uri) {
    if (error is ApiException) throw error;

    if (kDebugMode) {
      debugPrint('[ApiService] $method ${uri.toString()} failed: $error');
    }

    if (error is TimeoutException || _isTimeoutError(error)) {
      throw ApiException(message: _timeoutMessage(uri));
    }
    if (error is HandshakeException || error is TlsException) {
      throw ApiException(
        message: Env.isProductionHost
            ? 'Secure connection to Foodeez failed. Check your network and try again.'
            : 'Secure connection failed for ${uri.host}.',
      );
    }
    if (error is SocketException || error is http.ClientException) {
      if (_isTimeoutError(error)) {
        throw ApiException(message: _timeoutMessage(uri));
      }
      throw ApiException(message: _connectionMessage(uri));
    }
    throw ApiException(message: error.toString());
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request,
    String method,
    Uri uri, {
    bool authenticated = false,
    bool allowAuthRetry = true,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await request().timeout(_timeout);

        if (response.statusCode == 401 &&
            authenticated &&
            allowAuthRetry) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            return _send(
              request,
              method,
              uri,
              authenticated: authenticated,
              allowAuthRetry: false,
            );
          }
          await _handleUnauthorized();
          _throwIfError(response);
        }

        _throwIfError(response);
        return _decodeBody(response);
      } catch (e) {
        lastError = e;
        final canRetry = attempt < _maxAttempts && _isRetryable(e);
        if (canRetry) {
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
        _rethrowAsApiException(e, method, uri);
      }
    }

    _rethrowAsApiException(lastError ?? Exception('Unknown error'), method, uri);
  }

  Future<dynamic> get(
    String path, {
    ApiClientType client = ApiClientType.customer,
    Map<String, String>? query,
    bool authenticated = false,
  }) async {
    final uri = _uri(client, path, query);
    final headers = await _headers(client: client, authenticated: authenticated);
    return _send(
      () => _client.get(uri, headers: headers),
      'GET',
      uri,
      authenticated: authenticated,
    );
  }

  Future<dynamic> post(
    String path, {
    ApiClientType client = ApiClientType.customer,
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = _uri(client, path);
    final headers = await _headers(client: client, authenticated: authenticated);
    return _send(
      () => _client.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      'POST',
      uri,
      authenticated: authenticated,
    );
  }

  Future<dynamic> patch(
    String path, {
    ApiClientType client = ApiClientType.customer,
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = _uri(client, path);
    final headers = await _headers(client: client, authenticated: authenticated);
    return _send(
      () => _client.patch(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      'PATCH',
      uri,
      authenticated: authenticated,
    );
  }

  Future<dynamic> delete(
    String path, {
    ApiClientType client = ApiClientType.customer,
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = _uri(client, path);
    final headers = await _headers(client: client, authenticated: authenticated);
    return _send(
      () => _client.delete(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      'DELETE',
      uri,
      authenticated: authenticated,
    );
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService(
    ref.watch(tokenStorageProvider),
    ref.watch(httpClientProvider),
  );
  service.onSessionExpired = () async {
    await ref.read(authControllerProvider.notifier).logout();
  };
  return service;
});
