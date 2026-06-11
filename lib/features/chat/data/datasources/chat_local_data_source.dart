import 'package:injectable/injectable.dart';
import '../../../../core/storage/cache_manager.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

/// Local data source for caching chat messages and conversations.
///
/// Provides offline access to previously loaded messages and the chat list.
/// Uses [CacheManager] with TTL-based expiration for data freshness.
///
/// Requirements: 11.1, 11.9
abstract class ChatLocalDataSource {
  /// Caches messages for an order.
  ///
  /// [orderId] is the order whose messages to cache.
  /// [messages] is the list of message models to store.
  Future<void> cacheMessages(String orderId, List<ChatMessageModel> messages);

  /// Retrieves cached messages for an order.
  ///
  /// Returns null if no cached messages exist or cache is expired.
  Future<List<ChatMessageModel>?> getCachedMessages(String orderId);

  /// Caches the chat conversation list.
  ///
  /// [conversations] is the list of conversation models to store.
  Future<void> cacheChatList(List<ChatConversationModel> conversations);

  /// Retrieves the cached chat conversation list.
  ///
  /// Returns null if no cached list exists or cache is expired.
  Future<List<ChatConversationModel>?> getCachedChatList();

  /// Appends a single message to the cached messages for an order.
  ///
  /// Used for optimistic UI when sending messages or receiving via WebSocket.
  Future<void> appendMessage(String orderId, ChatMessageModel message);

  /// Clears cached messages for a specific order.
  Future<void> clearMessages(String orderId);

  /// Clears all chat-related cache.
  Future<void> clearAll();
}

/// Implementation of [ChatLocalDataSource] using [CacheManager].
@LazySingleton(as: ChatLocalDataSource)
class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  const ChatLocalDataSourceImpl({required this.cacheManager});

  final CacheManager cacheManager;

  static const String _messagesKeyPrefix = 'chat_messages_';
  static const String _chatListKey = 'chat_list';

  @override
  Future<void> cacheMessages(
    String orderId,
    List<ChatMessageModel> messages,
  ) async {
    final key = '$_messagesKeyPrefix$orderId';
    final jsonList = messages.map((m) => m.toJson()).toList();
    await cacheManager.put(key, jsonList);
  }

  @override
  Future<List<ChatMessageModel>?> getCachedMessages(String orderId) async {
    final key = '$_messagesKeyPrefix$orderId';
    final isExpired = await cacheManager.isExpired(key);
    if (isExpired) return null;

    final data = await cacheManager.get<List<dynamic>>(key);
    if (data == null) return null;

    return data
        .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheChatList(List<ChatConversationModel> conversations) async {
    final jsonList = conversations.map((c) => c.toJson()).toList();
    await cacheManager.put(_chatListKey, jsonList);
  }

  @override
  Future<List<ChatConversationModel>?> getCachedChatList() async {
    final isExpired = await cacheManager.isExpired(_chatListKey);
    if (isExpired) return null;

    final data = await cacheManager.get<List<dynamic>>(_chatListKey);
    if (data == null) return null;

    return data
        .map(
          (item) =>
              ChatConversationModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> appendMessage(String orderId, ChatMessageModel message) async {
    final key = '$_messagesKeyPrefix$orderId';
    final existing = await getCachedMessages(orderId);
    final messages = [...?existing, message]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final jsonList = messages.map((m) => m.toJson()).toList();
    await cacheManager.put(key, jsonList);
  }

  @override
  Future<void> clearMessages(String orderId) async {
    final key = '$_messagesKeyPrefix$orderId';
    await cacheManager.invalidate(key);
  }

  @override
  Future<void> clearAll() async {
    await cacheManager.invalidate(_chatListKey);
    // Note: Individual message caches are cleared per-order
    // A full clear would require tracking all cached order IDs
  }
}
