import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/support_model.dart';
import '../data/repositories/support_repository.dart';

final supportControllerProvider =
    AsyncNotifierProvider<SupportController, List<SupportTicketModel>>(
  SupportController.new,
);

class SupportController extends AsyncNotifier<List<SupportTicketModel>> {
  @override
  Future<List<SupportTicketModel>> build() async => _load();

  Future<List<SupportTicketModel>> _load() async {
    return ref.read(supportRepositoryProvider).getTickets();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> createTicket({
    required String type,
    required String description,
    String priority = 'MEDIUM',
    String? orderId,
  }) async {
    await ref.read(supportRepositoryProvider).createTicket(
          type: type,
          description: description,
          priority: priority,
          orderId: orderId,
        );
    await refresh();
  }
}
