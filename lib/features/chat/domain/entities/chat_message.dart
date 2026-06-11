import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

/// Represents a single chat message within an order conversation.
///
/// Messages can be text, image, or system-generated. Each message tracks
/// its delivery status (sending, sent, delivered, failed) for optimistic UI.
///
/// Requirements: 11.1, 11.2, 11.3
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.deliveryStatus,
    this.mediaUrl,
    this.caption,
  });

  /// Unique identifier for this message.
  final String id;

  /// The order this message belongs to.
  final String orderId;

  /// The user ID of the message sender.
  final String senderId;

  /// Display name of the message sender.
  final String senderName;

  /// The type of message (text, image, system).
  final MessageType type;

  /// The message content (text body or image description).
  final String content;

  /// URL of the attached media (for image messages).
  final String? mediaUrl;

  /// Optional caption for image messages (max 500 characters).
  final String? caption;

  /// Whether this message has been read by the recipient.
  final bool isRead;

  /// When this message was created/sent.
  final DateTime createdAt;

  /// Client-side delivery status tracking.
  final MessageDeliveryStatus deliveryStatus;

  /// Creates a copy of this message with the given fields replaced.
  ChatMessage copyWith({
    String? id,
    String? orderId,
    String? senderId,
    String? senderName,
    MessageType? type,
    String? content,
    String? mediaUrl,
    String? caption,
    bool? isRead,
    DateTime? createdAt,
    MessageDeliveryStatus? deliveryStatus,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      caption: caption ?? this.caption,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderId,
    senderId,
    senderName,
    type,
    content,
    mediaUrl,
    caption,
    isRead,
    createdAt,
    deliveryStatus,
  ];
}
