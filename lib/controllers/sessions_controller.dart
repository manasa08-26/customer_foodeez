import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/session_model.dart';
import '../data/repositories/auth_repository.dart';

final sessionsControllerProvider =
    AsyncNotifierProvider<SessionsController, List<SessionModel>>(
  SessionsController.new,
);

class SessionsController extends AsyncNotifier<List<SessionModel>> {
  @override
  Future<List<SessionModel>> build() async => _load();

  Future<List<SessionModel>> _load() async {
    return ref.read(authRepositoryProvider).getSessions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> revoke(String deviceId) async {
    await ref.read(authRepositoryProvider).revokeSession(deviceId);
    await refresh();
  }

  Future<void> logoutAll() async {
    await ref.read(authRepositoryProvider).logoutAll();
  }
}
