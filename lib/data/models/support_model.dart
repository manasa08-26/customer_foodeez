import '../../core/utils/json_parsers.dart';

class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.type,
    required this.status,
    required this.description,
    this.priority,
    this.orderId,
    this.createdAt,
  });

  final String id;
  final String type;
  final String status;
  final String description;
  final String? priority;
  final String? orderId;
  final DateTime? createdAt;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: JsonParsers.stringValue(json['id']),
      type: JsonParsers.stringValue(json['type']),
      status: JsonParsers.stringValue(json['status']),
      description: JsonParsers.stringValue(json['description']),
      priority: json['priority']?.toString(),
      orderId: json['orderId']?.toString(),
      createdAt: DateTime.tryParse(
        JsonParsers.stringValue(json['createdAt']),
      ),
    );
  }
}
