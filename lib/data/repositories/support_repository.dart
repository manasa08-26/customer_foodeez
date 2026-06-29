import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/json_parsers.dart';
import '../models/support_model.dart';

class SupportRepository {
  SupportRepository(this._api);

  final ApiService _api;

  Future<List<SupportTicketModel>> getTickets({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(
      ApiEndpoints.supportTickets,
      authenticated: true,
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final list = _extractList(res);
    return list
        .whereType<Map>()
        .map((e) => SupportTicketModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createTicket({
    required String type,
    required String description,
    String priority = 'MEDIUM',
    String? orderId,
  }) async {
    await _api.post(
      ApiEndpoints.supportTickets,
      authenticated: true,
      body: {
        'type': type,
        'description': description,
        'priority': priority,
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
      },
    );
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    final map = JsonParsers.mapValue(res);
    final data = JsonParsers.mapValue(map['data']);
    if (data['tickets'] is List) return data['tickets'] as List;
    if (data['items'] is List) return data['items'] as List;
    if (map['tickets'] is List) return map['tickets'] as List;
    return [];
  }
}

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiServiceProvider));
});
