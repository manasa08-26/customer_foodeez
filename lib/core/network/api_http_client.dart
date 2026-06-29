import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

HttpClient _createHttpClient() {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 30)
    // Avoid system proxy misconfiguration on emulators.
    ..findProxy = (_) => 'DIRECT';
  return client;
}

/// Shared HTTP client with explicit connection timeouts.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = IOClient(_createHttpClient());
  ref.onDispose(client.close);
  return client;
});
