import 'dart:io';

import '../../../../core/error/result.dart';
import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';

/// Abstract repository defining in-app chat operations.
///
/// Combines REST (message history, image upload, mark-read) with
/// WebSocket (real-time messages, typing indicators) for a complete
/// chat experience within order contexts.
///
/// Requirements: 11.1, 11.2, 11.3, 11.6, 11.8
abstract class ChatRepository {
  /// Fetches message history for an order with cursor-based pagination.
  ///
  /// Returns up to [limit] messages (default 50) starting from [cursor].
  /// Messages are ordered by creation time descending (newest first).
  /// [orderId] is the order whose chat to fetch.
  /// [cursor] is the timestamp-based cursor for loading older messages.
  Future<Result<List<ChatMessage>>> getMessages(
    String orderId, {
    String? cursor,
    int limit = 50,
    bool isWorker = false,
  });

  /// Sends a text message in the order's chat.
  ///
  /// [orderId] is the order context.
  /// [content] is the message text (1-2000 characters, non-whitespace-only).
  /// Delivers via WebSocket and returns the confirmed message.
  Future<Result<ChatMessage>> sendTextMessage(
    String orderId,
    String content, {
    bool isWorker = false,
  });

  /// Sends an image message in the order's chat.
  ///
  /// [orderId] is the order context.
  /// [image] is the image file (JPG/PNG, max 10MB).
  /// [caption] is an optional caption (max 500 characters).
  /// Uploads via REST and returns the confirmed message.
  Future<Result<ChatMessage>> sendImageMessage(
    String orderId,
    File image, {
    String? caption,
    bool isWorker = false,
  });

  /// Marks all messages in the order's chat as read.
  ///
  /// [orderId] is the order whose messages to mark as read.
  Future<Result<void>> markAsRead(String orderId, {bool isWorker = false});

  /// Fetches the list of active chat conversations.
  ///
  /// Returns conversations sorted by last message time (newest first),
  /// showing worker name, avatar, online status, last message preview,
  /// order title, and unread count.
  Future<Result<List<ChatConversation>>> getChatList({bool isWorker = false});

  /// Stream of incoming messages from WebSocket.
  ///
  /// Emits [ChatMessage] whenever a new message is received via WebSocket.
  Stream<ChatMessage> get incomingMessageStream;

  /// Stream of typing indicators from WebSocket.
  ///
  /// Emits `true` when the counterpart starts typing, `false` when they stop.
  Stream<bool> get typingStream;

  /// Sends a typing indicator to the counterpart.
  ///
  /// [orderId] is the order/chat context.
  void sendTypingIndicator(String orderId);

  /// Connects to the chat WebSocket channel for real-time updates.
  ///
  /// [orderId] is the order to connect to.
  Future<void> connectToChat(String orderId);

  /// Disconnects from the chat WebSocket channel.
  Future<void> disconnectFromChat();
}
