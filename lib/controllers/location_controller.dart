import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Delivery coordinates used for nearby / search API calls.
class DeliveryLocation {
  const DeliveryLocation({
    required this.lat,
    required this.lng,
    required this.label,
    this.isManual = false,
  });

  final double lat;
  final double lng;
  final String label;
  final bool isManual;

  static const fallback = DeliveryLocation(
    lat: 17.385,
    lng: 78.4867,
    label: 'Hyderabad',
  );
}

/// Preset cities for quick manual location pick.
class DeliveryCityPreset {
  const DeliveryCityPreset(this.label, this.lat, this.lng);

  final String label;
  final double lat;
  final double lng;

  static const presets = [
    DeliveryCityPreset('Hyderabad', 17.385, 78.4867),
    DeliveryCityPreset('Bengaluru', 12.9716, 77.5946),
    DeliveryCityPreset('Mumbai', 19.076, 72.8777),
    DeliveryCityPreset('Delhi', 28.6139, 77.209),
    DeliveryCityPreset('Chennai', 13.0827, 80.2707),
    DeliveryCityPreset('Pune', 18.5204, 73.8567),
  ];
}

class _GeoResult {
  const _GeoResult({required this.lat, required this.lng, this.label});

  final double lat;
  final double lng;
  final String? label;
}

Future<_GeoResult?> _geocodeAddress(String query) async {
  final uri = Uri.https(
    'nominatim.openstreetmap.org',
    '/search',
    {
      'q': query,
      'format': 'json',
      'limit': '1',
      'countrycodes': 'in',
    },
  );
  final res = await http.get(
    uri,
    headers: const {'User-Agent': 'FoodeezCustomer/1.0'},
  );
  if (res.statusCode != 200) return null;

  final list = jsonDecode(res.body);
  if (list is! List || list.isEmpty) return null;

  final item = list.first;
  if (item is! Map) return null;

  final lat = double.tryParse(item['lat']?.toString() ?? '');
  final lng = double.tryParse(item['lon']?.toString() ?? '');
  if (lat == null || lng == null) return null;

  final display = item['display_name']?.toString();
  return _GeoResult(lat: lat, lng: lng, label: display);
}

Future<String?> _reverseGeocodeLabel(double lat, double lng) async {
  final uri = Uri.https(
    'nominatim.openstreetmap.org',
    '/reverse',
    {
      'lat': '$lat',
      'lon': '$lng',
      'format': 'json',
      'zoom': '14',
    },
  );
  final res = await http.get(
    uri,
    headers: const {'User-Agent': 'FoodeezCustomer/1.0'},
  );
  if (res.statusCode != 200) return null;

  final body = jsonDecode(res.body);
  if (body is! Map) return null;
  final address = body['address'];
  if (address is! Map) return body['display_name']?.toString();

  final parts = <String>[
    if (address['suburb'] != null) address['suburb'].toString(),
    if (address['city'] != null) address['city'].toString(),
    if (address['town'] != null) address['town'].toString(),
    if (address['state_district'] != null)
      address['state_district'].toString(),
  ].where((p) => p.isNotEmpty).toList();

  if (parts.isNotEmpty) return parts.take(2).join(', ');
  return body['display_name']?.toString();
}

class DeliveryLocationController extends Notifier<DeliveryLocation> {
  static const _kLat = 'delivery_lat';
  static const _kLng = 'delivery_lng';
  static const _kLabel = 'delivery_label';
  static const _kManual = 'delivery_manual';

  @override
  DeliveryLocation build() {
    Future.microtask(_loadSaved);
    return DeliveryLocation.fallback;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kLat);
    final lng = prefs.getDouble(_kLng);
    final label = prefs.getString(_kLabel);
    if (lat != null && lng != null && label != null && label.isNotEmpty) {
      state = DeliveryLocation(
        lat: lat,
        lng: lng,
        label: label,
        isManual: prefs.getBool(_kManual) ?? false,
      );
      return;
    }
    await useCurrentLocation(silent: true);
  }

  Future<void> _persist(DeliveryLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, location.lat);
    await prefs.setDouble(_kLng, location.lng);
    await prefs.setString(_kLabel, location.label);
    await prefs.setBool(_kManual, location.isManual);
  }

  Future<String?> useCurrentLocation({bool silent = false}) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return silent
            ? null
            : 'Location permission denied. Enter your area manually.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );

      var label = 'Current location';
      try {
        label = await _reverseGeocodeLabel(pos.latitude, pos.longitude) ??
            label;
      } catch (_) {}

      final location = DeliveryLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        label: label,
        isManual: false,
      );
      state = location;
      await _persist(location);
      return null;
    } catch (_) {
      return silent ? null : 'Could not detect GPS location. Try entering manually.';
    }
  }

  Future<String?> setManualAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return 'Enter a valid area or city name.';

    try {
      final result = await _geocodeAddress(trimmed);
      if (result == null) {
        return 'Location not found. Try a nearby city or landmark.';
      }
      final location = DeliveryLocation(
        lat: result.lat,
        lng: result.lng,
        label: trimmed,
        isManual: true,
      );
      state = location;
      await _persist(location);
      return null;
    } catch (_) {
      return 'Could not find that location. Check your connection and try again.';
    }
  }

  Future<void> setPreset(DeliveryCityPreset preset) async {
    final location = DeliveryLocation(
      lat: preset.lat,
      lng: preset.lng,
      label: preset.label,
      isManual: true,
    );
    state = location;
    await _persist(location);
  }
}

final deliveryLocationProvider =
    NotifierProvider<DeliveryLocationController, DeliveryLocation>(
  DeliveryLocationController.new,
);

/// Legacy alias — prefer [deliveryLocationProvider].
@Deprecated('Use deliveryLocationProvider')
final locationResolverProvider = Provider<LocationResolver>((ref) {
  final loc = ref.watch(deliveryLocationProvider);
  return LocationResolver(loc);
});

@Deprecated('Use DeliveryLocation')
class LocationState {
  const LocationState({required this.lat, required this.lng});

  final double lat;
  final double lng;

  static const fallback = LocationState(lat: 17.385, lng: 78.4867);
}

@Deprecated('Use DeliveryLocationController')
class LocationResolver {
  LocationResolver(this._location);

  final DeliveryLocation _location;

  LocationState get cached =>
      LocationState(lat: _location.lat, lng: _location.lng);

  Future<LocationState> resolve() async => cached;
}
