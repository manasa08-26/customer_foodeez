import '../../core/utils/json_parsers.dart';

/// Generic paginated list wrapper from API responses.
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  static PaginatedResponse<T> fromJson<T>(
    dynamic json,
    T Function(Map<String, dynamic>) fromMap, {
    String itemsKey = 'items',
  }) {
    if (json is List) {
      final items = _parseItems(json, fromMap);
      return PaginatedResponse(
        items: items,
        page: 1,
        limit: items.length,
        total: items.length,
        hasMore: false,
      );
    }

    final map = JsonParsers.mapValue(json);

    final rawItems = map[itemsKey] ??
        map['data'] ??
        map['restaurants'] ??
        map['orders'] ??
        [];

    final items = _parseItems(JsonParsers.listValue(rawItems), fromMap);

    final page = JsonParsers.intOr(map['page'], 1);
    final limit = JsonParsers.intOr(map['limit'], items.length);
    final total = JsonParsers.intOr(map['total'], items.length);
    final hasMore = JsonParsers.boolValue(map['hasMore']) ??
        JsonParsers.boolValue(map['hasNextPage']) ??
        (page * limit < total);

    return PaginatedResponse(
      items: items,
      page: page,
      limit: limit,
      total: total,
      hasMore: hasMore,
    );
  }

  static List<T> _parseItems<T>(
    List<dynamic> rawItems,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    final items = <T>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      try {
        items.add(fromMap(Map<String, dynamic>.from(raw)));
      } catch (_) {
        // Skip malformed records instead of crashing the whole list.
      }
    }
    return items;
  }
}
