import '../constants/env.dart';

/// Resolves relative media paths to absolute URLs (matches web `resolveMediaUrl`).
String? resolveMediaUrl(String? mediaPath) {
  if (mediaPath == null || mediaPath.isEmpty) return null;
  if (mediaPath.startsWith('http://') || mediaPath.startsWith('https://')) {
    return mediaPath;
  }
  final origin = Env.apiBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  final path = mediaPath.startsWith('/') ? mediaPath : '/$mediaPath';
  return '$origin$path';
}
