import 'dart:async';
import 'package:injectable/injectable.dart';

import '../../../../core/network/websocket_events.dart';
import '../../../../core/network/websocket_manager.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

/// WebSocket data source for real-time chat communication.
///
/// Connects to the chat WebSocket channel and provides streams of
/// incoming messages and typing indicators. Handles sending typing
/// events to the counterpart.
///
/// Requirements: 11.2, 11.4, 11.5
abstract class ChatWebSocketDataSource {
  /// Stream of incoming chat messages from WebSocket.
  Stream<ChatMessage> get incomingMessageStream;

  /// Stream of typing indicators from WebSocket.
  ///
  /// Emits `true` when the counterpart starts typing, `false` when they stop.
  Stream<bool> get typingStream;

  /// Connects to the chat WebSocket channel for the given order.
  ///
  /// [orderId] is the order whose chat to connect to.
  /// [token] is the JWT token for authentication.
  Future<void> connect(String orderId, String token);

  /// Disconnects from the chat WebSocket channel.
  Future<void> disconnect();

  /// Sends a typing indicator to the counterpart.
  ///
  /// [orderId] is the order/chat context.
  void sendTypingIndicator(String orderId);

  /// Whether the WebSocket is currently connected.
  bool get isConnected;
}

/// Implementation of [ChatWebSocketDataSource] using [WebSocketManager].
@LazySingleton(as: ChatWebSocketDataSource)
class ChatWebSocketDataSourceImpl implements ChatWebSocketDataSource {
  ChatWebSocketDataSourceImpl({required this.webSocketManager});

  final WebSocketManager webSocketManager;

  static const String _chatChannel = 'chat';

  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<bool> _typingController =
      StreamController<bool>.broadcast();

  StreamSubscription<WebSocketEvent>? _eventSubscription;

  @override
  Stream<ChatMessage> get incomingMessageStream => _messageController.stream;

  @override
  Stream<bool> get typingStream => _typingController.stream;

  @override
  bool get isConnected => webSocketManager.isConnected;

  @override
  Future<void> connect(String orderId, String token) async {
    // Subscribe to WebSocket events before connecting
    await _eventSubscription?.cancel();
    _eventSubscription = webSocketManager.eventStream.listen(_handleEvent);

    await webSocketManager.connect(_chatChannel, orderId, token);
  }

  @override
  Future<void> disconnect() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await webSocketManager.disconnect(_chatChannel);
  }

  @override
  void sendTypingIndicator(String orderId) {
    webSocketManager.send(_chatChannel, {
      'type': 'typing',
      'order_id': orderId,
      'is_typing': true,
    });
  }

  /// Handles incoming WebSocket events and routes them to appropriate streams.
  void _handleEvent(WebSocketEvent event) {
    switch (event) {
      case NewMessageEvent():
        final model = ChatMessageModel.fromJson(event.messageData);
        final message = model.toEntity();
        if (!_messageController.isClosed) {
          _messageController.add(message);
        }
      case TypingEvent():
        if (!_typingController.isClosed) {
          _typingController.add(event.isTyping);
        }
      case MessageReadEvent():
        // MessageReadEvent is handled at the repository level
        // to update existing messages' read status
        break;
      default:
        // Ignore non-chat events
        break;
    }
  }

  /// Releases resources. Call when this data source is no longer needed.
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _messageController.close();
    await _typingController.close();
  }
}
