part of 'chat_bloc.dart';

/// Sealed class representing all chat events.
///
/// Events are dispatched from the UI layer or WebSocket subscriptions
/// to trigger state changes in the [ChatBloc].
sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched to load messages for an order's chat.
///
/// Supports cursor-based pagination for loading older messages.
/// Validates: Requirement 11.1, 11.8
class LoadMessages extends ChatEvent {
  /// Creates a [LoadMessages] event.
  const LoadMessages({
    required this.orderId,
    this.cursor,
  });

  /// The order whose chat messages to load.
  final String orderId;

  /// Optional cursor for loading older messages (pagination).
  final String? cursor;

  @override
  List<Object?> get props => [orderId, cursor];
}

/// Event dispatched when the user sends a text message.
///
/// Validates: Requirement 11.2, 11.11
class SendTextMessage extends ChatEvent {
  /// Creates a [SendTextMessage] event.
  const SendTextMessage({
    required this.orderId,
    required this.content,
  });

  /// The order context for this message.
  final String orderId;

  /// The text content (1-2000 chars, non-whitespace-only).
  final String content;

  @override
  List<Object?> get props => [orderId, content];
}

/// Event dispatched when the user sends an image message.
///
/// Validates: Requirement 11.3, 11.10
class SendImageMessage extends ChatEvent {
  /// Creates a [SendImageMessage] event.
  const SendImageMessage({
    required this.orderId,
    required this.image,
    this.caption,
  });

  /// The order context for this message.
  final String orderId;

  /// The image file (JPG/PNG, max 10MB).
  final File image;

  /// Optional caption (max 500 characters).
  final String? caption;

  @override
  List<Object?> get props => [orderId, image, caption];
}

/// Event dispatched when a new message is received via WebSocket.
///
/// Validates: Requirement 11.4
class MessageReceived extends ChatEvent {
  /// Creates a [MessageReceived] event.
  const MessageReceived({required this.message});

  /// The incoming chat message.
  final ChatMessage message;

  @override
  List<Object?> get props => [message];
}

/// Event dispatched when the user starts typing.
///
/// Validates: Requirement 11.5
class TypingStarted extends ChatEvent {
  /// Creates a [TypingStarted] event.
  const TypingStarted({required this.orderId});

  /// The order context.
  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// Event dispatched to mark all messages as read.
///
/// Validates: Requirement 11.6
class MarkAsRead extends ChatEvent {
  /// Creates a [MarkAsRead] event.
  const MarkAsRead({required this.orderId});

  /// The order whose messages to mark as read.
  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// Event dispatched when the counterpart's typing status changes.
class TypingStatusChanged extends ChatEvent {
  /// Creates a [TypingStatusChanged] event.
  const TypingStatusChanged({required this.isTyping});

  /// Whether the counterpart is currently typing.
  final bool isTyping;

  @override
  List<Object?> get props => [isTyping];
}

/// Event dispatched to retry sending a failed message.
///
/// Validates: Requirement 11.9
class RetryMessage extends ChatEvent {
  /// Creates a [RetryMessage] event.
  const RetryMessage({required this.message});

  /// The failed message to retry.
  final ChatMessage message;

  @override
  List<Object?> get props => [message];
}
