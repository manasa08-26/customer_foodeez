import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists last-viewed restaurant for cart header fallback (web `currentRestaurant`).
class CartRestaurantCache {
  CartRestaurantCache._();

  static const _key = 'currentRestaurant';

  static Future<void> save({
    required String name,
    String location = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({'name': name, 'location': location}),
    );
  }

  static Future<({String name, String location})?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        name: map['name']?.toString() ?? 'Your Restaurant',
        location: map['location']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
