import 'package:equatable/equatable.dart';

/// Represents a chat conversation entry in the chat list.
///
/// Displays summary information for each active conversation including
/// the worker's info, last message preview, and unread count.
///
/// Requirements: 11.7
class ChatConversation extends Equatable {
  const ChatConversation({
    required this.orderId,
    required this.workerName,
    required this.isOnline,
    required this.unreadCount,
    this.workerAvatarUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.orderTitle,
  });

  /// The order ID this conversation belongs to.
  final String orderId;

  /// The worker's display name.
  final String workerName;

  /// The worker's avatar URL, or null if not set.
  final String? workerAvatarUrl;

  /// Whether the worker is currently online.
  final bool isOnline;

  /// Preview of the last message (truncated to 80 characters).
  final String? lastMessage;

  /// Timestamp of the last message.
  final DateTime? lastMessageTime;

  /// The title of the associated order.
  final String? orderTitle;

  /// Number of unread messages in this conversation.
  final int unreadCount;

  /// Creates a copy of this conversation with the given fields replaced.
  ChatConversation copyWith({
    String? orderId,
    String? workerName,
    String? workerAvatarUrl,
    bool? isOnline,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? orderTitle,
    int? unreadCount,
  }) {
    return ChatConversation(
      orderId: orderId ?? this.orderId,
      workerName: workerName ?? this.workerName,
      workerAvatarUrl: workerAvatarUrl ?? this.workerAvatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      orderTitle: orderTitle ?? this.orderTitle,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        workerName,
        workerAvatarUrl,
        isOnline,
        lastMessage,
        lastMessageTime,
        orderTitle,
        unreadCount,
      ];
}
