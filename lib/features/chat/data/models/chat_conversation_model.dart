import '../../domain/entities/chat_conversation.dart';

/// Data transfer object for chat conversations from the API.
///
/// Maps the JSON response from the chat list endpoint to the domain
/// [ChatConversation] entity.
class ChatConversationModel {
  const ChatConversationModel({
    required this.orderId,
    required this.workerName,
    required this.isOnline,
    required this.unreadCount,
    this.workerAvatarUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.orderTitle,
  });

  /// Creates a [ChatConversationModel] from a JSON map.
  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      orderId: json['order_id'] as String? ?? '',
      workerName: json['worker_name'] as String? ?? '',
      workerAvatarUrl: json['worker_avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      orderTitle: json['order_title'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  final String orderId;
  final String workerName;
  final String? workerAvatarUrl;
  final bool isOnline;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? orderTitle;
  final int unreadCount;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'worker_name': workerName,
        if (workerAvatarUrl != null) 'worker_avatar_url': workerAvatarUrl,
        'is_online': isOnline,
        if (lastMessage != null) 'last_message': lastMessage,
        if (lastMessageTime != null)
          'last_message_time': lastMessageTime!.toIso8601String(),
        if (orderTitle != null) 'order_title': orderTitle,
        'unread_count': unreadCount,
      };

  /// Converts this DTO to the domain entity.
  ChatConversation toEntity() => ChatConversation(
        orderId: orderId,
        workerName: workerName,
        workerAvatarUrl: workerAvatarUrl,
        isOnline: isOnline,
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        orderTitle: orderTitle,
        unreadCount: unreadCount,
      );
}
