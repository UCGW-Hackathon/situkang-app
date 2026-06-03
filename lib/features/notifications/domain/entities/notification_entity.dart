import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type, // 'order', 'purchase', 'chat', 'promo', 'system', 'payment'
    required this.createdAt,
    required this.isRead,
    this.targetId, // ID of order, chat, etc.
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String? targetId;

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        createdAt,
        isRead,
        targetId,
      ];
}
