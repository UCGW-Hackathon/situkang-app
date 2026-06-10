import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

/// Remote data source for chat REST API calls.
///
/// Handles message history retrieval, image uploads, mark-as-read,
/// and chat list fetching. Real-time messaging is handled by
/// [ChatWebSocketDataSource].
///
/// Requirements: 11.1, 11.3, 11.6, 11.7, 11.8
abstract class ChatRemoteDataSource {
  /// Fetches message history for an order with cursor-based pagination.
  ///
  /// [orderId] is the order whose chat to fetch.
  /// [cursor] is the timestamp-based cursor for loading older messages.
  /// [limit] is the number of messages per page (default 50).
  Future<List<ChatMessageModel>> getMessages(
    String orderId, {
    String? cursor,
    int limit = 50,
    bool isWorker = false,
  });

  /// Sends a text message via REST (fallback when WebSocket unavailable).
  ///
  /// [orderId] is the order context.
  /// [content] is the message text.
  Future<ChatMessageModel> sendTextMessage(
    String orderId,
    String content, {
    bool isWorker = false,
  });

  /// Uploads an image message with optional caption.
  ///
  /// [orderId] is the order context.
  /// [image] is the image file (JPG/PNG, max 10MB).
  /// [caption] is an optional caption (max 500 characters).
  Future<ChatMessageModel> sendImageMessage(
    String orderId,
    File image, {
    String? caption,
    bool isWorker = false,
  });

  /// Marks all messages in the order's chat as read.
  ///
  /// [orderId] is the order whose messages to mark as read.
  Future<void> markAsRead(String orderId, {bool isWorker = false});

  /// Fetches the list of active chat conversations.
  Future<List<ChatConversationModel>> getChatList();
}

/// Implementation of [ChatRemoteDataSource] using the [ApiClient].
@LazySingleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  const ChatRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<ChatMessageModel>> getMessages(
    String orderId, {
    String? cursor,
    int limit = 50,
    bool isWorker = false,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (cursor != null) {
      queryParams['cursor'] = cursor;
    }

    final response = await apiClient.get<Map<String, dynamic>>(
      isWorker
          ? ApiEndpoints.workerChatMessages(orderId)
          : ApiEndpoints.chatMessages(orderId),
      queryParams: queryParams,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No chat data received');
    }

    // Handle wrapped response format: { "status": "success", "data": { "messages": [...] } }
    final responseData = data['data'] as Map<String, dynamic>? ?? data;
    final messagesList = responseData['messages'] as List<dynamic>? ?? [];

    return messagesList
        .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatMessageModel> sendTextMessage(
    String orderId,
    String content, {
    bool isWorker = false,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      isWorker
          ? ApiEndpoints.workerChatMessages(orderId)
          : ApiEndpoints.chatMessages(orderId),
      data: {'message_type': 'text', 'content': content},
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No response data received');
    }

    final messageData = data['data'] as Map<String, dynamic>? ?? data;
    return ChatMessageModel.fromJson(messageData);
  }

  @override
  Future<ChatMessageModel> sendImageMessage(
    String orderId,
    File image, {
    String? caption,
    bool isWorker = false,
  }) async {
    final formData = FormData.fromMap(<String, dynamic>{
      'message_type': 'image',
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
      'caption': ?caption,
    });

    final response = await apiClient.upload<Map<String, dynamic>>(
      isWorker
          ? ApiEndpoints.workerChatMessages(orderId)
          : ApiEndpoints.chatMessages(orderId),
      data: formData,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No response data received');
    }

    final messageData = data['data'] as Map<String, dynamic>? ?? data;
    return ChatMessageModel.fromJson(messageData);
  }

  @override
  Future<void> markAsRead(String orderId, {bool isWorker = false}) async {
    await apiClient.patch<Map<String, dynamic>>(
      isWorker
          ? ApiEndpoints.workerChatMarkRead(orderId)
          : ApiEndpoints.chatMarkRead(orderId),
    );
  }

  @override
  Future<List<ChatConversationModel>> getChatList() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.chatList,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No chat list data received');
    }

    // Handle wrapped response format: { "status": "success", "data": { "conversations": [...] } }
    final responseData = data['data'] as Map<String, dynamic>? ?? data;
    final conversationsList =
        responseData['conversations'] as List<dynamic>? ?? [];

    return conversationsList
        .map(
          (item) =>
              ChatConversationModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
