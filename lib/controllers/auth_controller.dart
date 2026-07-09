import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/token_storage.dart';
import '../data/models/auth_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';

/// MVC Controller — auth business logic and session state.
class AuthController extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    _checkSession();
    return const AsyncValue.loading();
  }

  Future<void> _checkSession() async {
    final hasToken = await ref.read(tokenStorageProvider).hasValidToken();
    if (!hasToken) {
      state = const AsyncValue.data(false);
      return;
    }
    try {
      await ref.read(profileRepositoryProvider).getProfile();
      state = const AsyncValue.data(true);
    } catch (_) {
      final refreshed = await _tryRefreshTokens();
      state = AsyncValue.data(refreshed);
    }
  }

  Future<bool> _tryRefreshTokens() async {
    final storage = ref.read(tokenStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await storage.clear();
      return false;
    }
    try {
      final tokens = await ref.read(authRepositoryProvider).refreshTokens(
            refreshToken: refreshToken,
          );
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        name: tokens.name,
      );
      return true;
    } catch (_) {
      await storage.clear();
      return false;
    }
  }

  Future<void> refreshSession() => _checkSession();

  Future<bool> sendOtp(String email, OtpPurpose purpose) async {
    try {
      await ref.read(authRepositoryProvider).sendOtp(
            email: email,
            purpose: purpose,
          );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> login(String email, String otp) async {
    state = const AsyncValue.loading();
    try {
      final tokens = await ref.read(authRepositoryProvider).login(
            email: email,
            otp: otp,
          );
      await ref.read(tokenStorageProvider).saveTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            name: tokens.name,
          );
      state = const AsyncValue.data(true);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> signup({
    required String email,
    required String phone,
    required String otp,
    String? name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final tokens = await ref.read(authRepositoryProvider).signup(
            email: email,
            phone: phone,
            otp: otp,
            name: name,
          );
      await ref.read(tokenStorageProvider).saveTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            name: tokens.name ?? name,
          );
      state = const AsyncValue.data(true);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Clear local session even if remote logout fails.
    }
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncValue.data(false);
  }

  bool get isAuthenticated => state.value ?? false;
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<bool>>(AuthController.new);

/// Pending redirect path after login (e.g. return to restaurant after add-to-cart).
final authRedirectProvider =
    NotifierProvider<AuthRedirectController, String?>(AuthRedirectController.new);

class AuthRedirectController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? path) => state = path;

  void clear() => state = null;
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setMode(ThemeMode mode) => state = mode;
}
