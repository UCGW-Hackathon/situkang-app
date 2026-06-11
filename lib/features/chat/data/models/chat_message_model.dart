import '../../../../core/constants/enums.dart';
import '../../domain/entities/chat_message.dart';

/// Data transfer object for chat messages from the API.
///
/// Maps the JSON response from chat endpoints to the domain
/// [ChatMessage] entity.
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.mediaUrl,
    this.caption,
    this.deliveryStatus,
  });

  /// Creates a [ChatMessageModel] from a JSON map.
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? json['message_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName:
          json['sender_name'] as String? ??
          json['sender_type'] as String? ??
          '',
      type: MessageType.fromString(
        json['message_type'] as String? ?? json['type'] as String? ?? 'text',
      ),
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      mediaUrl: json['media_url'] as String?,
      caption: json['caption'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      deliveryStatus: json['delivery_status'] != null
          ? MessageDeliveryStatus.fromString(json['delivery_status'] as String)
          : null,
    );
  }

  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final String? caption;
  final bool isRead;
  final DateTime createdAt;
  final MessageDeliveryStatus? deliveryStatus;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'sender_id': senderId,
    'sender_name': senderName,
    'type': type.value,
    'content': content,
    if (mediaUrl != null) 'media_url': mediaUrl,
    if (caption != null) 'caption': caption,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    if (deliveryStatus != null) 'delivery_status': deliveryStatus!.value,
  };

  /// Converts this DTO to the domain entity.
  ChatMessage toEntity() => ChatMessage(
    id: id,
    orderId: orderId,
    senderId: senderId,
    senderName: senderName,
    type: type,
    content: content,
    mediaUrl: mediaUrl,
    caption: caption,
    isRead: isRead,
    createdAt: createdAt,
    deliveryStatus: deliveryStatus ?? MessageDeliveryStatus.delivered,
  );
}
