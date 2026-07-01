/// Runtime environment configuration via `--dart-define`.
///
/// Default API: https://int.foodeez.in/api/v1
///
/// Local backend override examples:
///   flutter run --dart-define=API_BASE_URL=http://localhost:4004/api/v1
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4004/api/v1
class Env {
  Env._();

  static const String productionApiBaseUrl = 'https://int.foodeez.in/customer/api/v1';

  /// Customer API (auth, discovery, cart, orders).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionApiBaseUrl,
  );

  static const String _customerApiOverride = String.fromEnvironment(
    'CUSTOMER_API_URL',
    defaultValue: '',
  );

  /// Customer service API (discovery, cart, orders, profile).
  static String get customerApiBaseUrl =>
      _customerApiOverride.isNotEmpty ? _customerApiOverride : apiBaseUrl;

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: true,
  );

  static bool get isProductionHost =>
      apiBaseUrl.startsWith('https://int.foodeez.in');
}
