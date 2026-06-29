import '../../core/utils/json_parsers.dart';

class SessionModel {
  const SessionModel({
    required this.deviceId,
    this.userAgent,
    this.lastUsedAt,
    this.isCurrent = false,
  });

  final String deviceId;
  final String? userAgent;
  final DateTime? lastUsedAt;
  final bool isCurrent;

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      deviceId: JsonParsers.stringValue(json['deviceId']),
      userAgent: json['userAgent']?.toString(),
      lastUsedAt: DateTime.tryParse(
        JsonParsers.stringValue(json['lastUsedAt'] ?? json['lastActiveAt']),
      ),
      isCurrent: JsonParsers.boolOr(json['isCurrent']),
    );
  }
}
