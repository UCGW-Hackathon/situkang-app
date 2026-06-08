/// WebSocket connection management for real-time features.
///
/// Provides channel-based WebSocket connections with automatic reconnection
/// using exponential backoff. Supports tracking, chat, and notification channels.
///
/// Requirements: 9.3, 9.4, 9.8, 11.2, 11.4, 24.1, 26.4, 26.5
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_constants.dart';
import 'websocket_events.dart';

/// Represents the current state of the WebSocket connection.
enum ConnectionState {
  /// Attempting to establish a connection.
  connecting,

  /// Connection is active and ready for communication.
  connected,

  /// Connection is closed (intentionally or not yet started).
  disconnected,

  /// Connection was lost and attempting to reconnect.
  reconnecting,
}

/// Abstract interface for WebSocket connection management.
///
/// Provides channel-based routing for different real-time features
/// (tracking, chat, notifications) with automatic reconnection.
abstract class WebSocketManager {
  /// Stream of all WebSocket events received across all channels.
  Stream<WebSocketEvent> get eventStream;

  /// Connects to a specific WebSocket channel.
  ///
  /// [channel] identifies the feature channel (e.g., 'tracking', 'chat').
  /// [orderId] is the context identifier for the channel.
  /// [token] is the JWT token for authentication.
  Future<void> connect(String channel, String orderId, String token);

  /// Disconnects from a specific channel.
  ///
  /// [channel] identifies which channel to disconnect from.
  Future<void> disconnect(String channel);

  /// Sends data to a specific channel.
  ///
  /// [channel] identifies the target channel.
  /// [data] is the JSON-serializable payload to send.
  void send(String channel, Map<String, dynamic> data);

  /// Whether any channel is currently connected.
  bool get isConnected;

  /// Stream of connection state changes.
  Stream<ConnectionState> get connectionStateStream;

  /// Disconnects all channels and releases resources.
  Future<void> dispose();
}

/// Internal representation of a single WebSocket channel connection.
class _ChannelConnection {
  _ChannelConnection({
    required this.channel,
    required this.orderId,
    required this.token,
  });

  final String channel;
  final String orderId;
  final String token;
  WebSocketChannel? webSocketChannel;
  StreamSubscription<dynamic>? subscription;
  int reconnectAttempts = 0;
  Timer? reconnectTimer;
  bool isIntentionalDisconnect = false;
}

/// Implementation of [WebSocketManager] using the `web_socket_channel` package.
///
/// Features:
/// - Channel-based routing (multiple simultaneous connections)
/// - Exponential backoff reconnection (1s start, doubles, capped at 60s, max 10 attempts)
/// - Connection state stream for UI feedback
/// - Automatic JSON parsing of incoming events
@LazySingleton(as: WebSocketManager)
class WebSocketManagerImpl implements WebSocketManager {
  /// Creates a [WebSocketManagerImpl].
  ///
  /// [baseUrl] overrides the default WebSocket URL (useful for testing).
  /// [channelFactory] allows injecting a custom WebSocket channel factory (for testing).
  WebSocketManagerImpl({
    String? baseUrl,
    WebSocketChannelFactory? channelFactory,
  })  : _baseUrl = baseUrl ?? AppConstants.webSocketUrl,
        _channelFactory = channelFactory ?? _defaultChannelFactory;

  @factoryMethod
  static WebSocketManagerImpl create() {
    return WebSocketManagerImpl();
  }

  final String _baseUrl;
  final WebSocketChannelFactory _channelFactory;

  final Map<String, _ChannelConnection> _connections = {};
  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  ConnectionState _currentState = ConnectionState.disconnected;

  @override
  Stream<WebSocketEvent> get eventStream => _eventController.stream;

  @override
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  bool get isConnected => _currentState == ConnectionState.connected;

  /// The current connection state (exposed for testing).
  ConnectionState get currentState => _currentState;

  @override
  Future<void> connect(String channel, String orderId, String token) async {
    // Disconnect existing connection for this channel if any.
    if (_connections.containsKey(channel)) {
      await disconnect(channel);
    }

    final connection = _ChannelConnection(
      channel: channel,
      orderId: orderId,
      token: token,
    );
    _connections[channel] = connection;

    await _establishConnection(connection);
  }

  @override
  Future<void> disconnect(String channel) async {
    final connection = _connections.remove(channel);
    if (connection == null) return;

    connection.isIntentionalDisconnect = true;
    connection.reconnectTimer?.cancel();
    connection.reconnectTimer = null;
    await connection.subscription?.cancel();
    connection.subscription = null;
    await connection.webSocketChannel?.sink.close();
    connection.webSocketChannel = null;

    _updateConnectionState();
  }

  @override
  void send(String channel, Map<String, dynamic> data) {
    final connection = _connections[channel];
    if (connection?.webSocketChannel == null) return;

    final payload = jsonEncode(data);
    connection!.webSocketChannel!.sink.add(payload);
  }

  @override
  Future<void> dispose() async {
    final channels = List<String>.from(_connections.keys);
    for (final channel in channels) {
      await disconnect(channel);
    }
    await _eventController.close();
    await _connectionStateController.close();
  }

  /// Establishes a WebSocket connection for the given channel.
  Future<void> _establishConnection(_ChannelConnection connection) async {
    _updateState(ConnectionState.connecting);

    try {
      final uri = Uri.parse(
        '$_baseUrl/${connection.channel}/${connection.orderId}',
      );

      connection.webSocketChannel = _channelFactory(
        uri,
        connection.token,
      );

      // Wait for the connection to be ready.
      await connection.webSocketChannel!.ready;

      connection.reconnectAttempts = 0;
      _updateState(ConnectionState.connected);

      connection.subscription =
          connection.webSocketChannel!.stream.listen(
        _handleMessage,
        onError: (Object error) => _handleError(connection, error),
        onDone: () => _handleDone(connection),
      );
    } catch (e) {
      _handleError(connection, e);
    }
  }

  /// Handles an incoming WebSocket message.
  void _handleMessage(dynamic data) {
    if (_eventController.isClosed) return;

    try {
      final Map<String, dynamic> json;
      if (data is String) {
        json = jsonDecode(data) as Map<String, dynamic>;
      } else {
        return;
      }

      final event = WebSocketEvent.fromJson(json);
      if (event != null) {
        _eventController.add(event);
      }
    } catch (_) {
      // Silently ignore malformed messages.
    }
  }

  /// Handles a WebSocket error.
  void _handleError(_ChannelConnection connection, Object error) {
    if (connection.isIntentionalDisconnect) return;
    _scheduleReconnect(connection);
  }

  /// Handles WebSocket stream completion (connection closed).
  void _handleDone(_ChannelConnection connection) {
    if (connection.isIntentionalDisconnect) return;
    _scheduleReconnect(connection);
  }

  /// Schedules a reconnection attempt with exponential backoff.
  ///
  /// Strategy: starts at 1s, doubles each attempt, capped at 60s, max 10 attempts.
  void _scheduleReconnect(_ChannelConnection connection) {
    if (connection.isIntentionalDisconnect) return;
    if (connection.reconnectAttempts >= AppConstants.wsMaxReconnectAttempts) {
      _updateState(ConnectionState.disconnected);
      return;
    }

    _updateState(ConnectionState.reconnecting);

    final delay = _calculateBackoffDelay(connection.reconnectAttempts);
    connection.reconnectAttempts++;

    connection.reconnectTimer?.cancel();
    connection.reconnectTimer = Timer(delay, () async {
      if (connection.isIntentionalDisconnect) return;

      // Clean up old connection.
      await connection.subscription?.cancel();
      connection.subscription = null;
      connection.webSocketChannel = null;

      await _establishConnection(connection);
    });
  }

  /// Calculates the backoff delay for a given attempt number.
  ///
  /// Formula: min(initialDelay * 2^attempt, maxDelay)
  Duration _calculateBackoffDelay(int attempt) {
    final initialMs = AppConstants.wsReconnectInitialDelay.inMilliseconds;
    final maxMs = AppConstants.wsReconnectMaxDelay.inMilliseconds;
    final delayMs = min(initialMs * pow(2, attempt).toInt(), maxMs);
    return Duration(milliseconds: delayMs);
  }

  /// Updates the overall connection state based on all active connections.
  void _updateConnectionState() {
    if (_connections.isEmpty) {
      _updateState(ConnectionState.disconnected);
    } else if (_connections.values.any(
      (c) => c.webSocketChannel != null && !c.isIntentionalDisconnect,
    )) {
      _updateState(ConnectionState.connected);
    } else {
      _updateState(ConnectionState.disconnected);
    }
  }

  /// Updates the connection state and emits to the stream.
  void _updateState(ConnectionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(newState);
      }
    }
  }
}

/// Factory function type for creating WebSocket channels.
///
/// Allows injection of mock channels for testing.
typedef WebSocketChannelFactory = WebSocketChannel Function(
  Uri uri,
  String token,
);

/// Default factory that creates a real WebSocket connection.
WebSocketChannel _defaultChannelFactory(Uri uri, String token) {
  return WebSocketChannel.connect(
    uri,
    protocols: ['Bearer', token],
  );
}
