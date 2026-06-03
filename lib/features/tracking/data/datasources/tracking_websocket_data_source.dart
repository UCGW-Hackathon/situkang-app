import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/network/websocket_events.dart';
import '../../../../core/network/websocket_manager.dart';
import '../../domain/entities/worker_location.dart';

/// WebSocket data source for real-time tracking updates.
///
/// Connects to the tracking WebSocket channel and provides streams
/// of location updates and status changes. This is the primary data
/// source for real-time tracking; REST polling is used as fallback.
///
/// Requirements: 9.3, 9.4
abstract class TrackingWebSocketDataSource {
  /// Stream of worker location updates from WebSocket.
  Stream<WorkerLocation> get locationStream;

  /// Stream of order status changes from WebSocket.
  Stream<OrderStatus> get statusStream;

  /// Connects to the tracking WebSocket channel for the given order.
  ///
  /// [orderId] is the order to track.
  /// [token] is the JWT token for authentication.
  Future<void> connect(String orderId, String token);

  /// Disconnects from the tracking WebSocket channel.
  Future<void> disconnect();

  /// Whether the WebSocket is currently connected.
  bool get isConnected;
}

/// Implementation of [TrackingWebSocketDataSource] using [WebSocketManager].
@LazySingleton(as: TrackingWebSocketDataSource)
class TrackingWebSocketDataSourceImpl implements TrackingWebSocketDataSource {
  TrackingWebSocketDataSourceImpl(this.webSocketManager);

  final WebSocketManager webSocketManager;

  static const String _trackingChannel = 'tracking';

  final StreamController<WorkerLocation> _locationController =
      StreamController<WorkerLocation>.broadcast();
  final StreamController<OrderStatus> _statusController =
      StreamController<OrderStatus>.broadcast();

  StreamSubscription<WebSocketEvent>? _eventSubscription;

  @override
  Stream<WorkerLocation> get locationStream => _locationController.stream;

  @override
  Stream<OrderStatus> get statusStream => _statusController.stream;

  @override
  bool get isConnected => webSocketManager.isConnected;

  @override
  Future<void> connect(String orderId, String token) async {
    // Subscribe to WebSocket events before connecting
    await _eventSubscription?.cancel();
    _eventSubscription = webSocketManager.eventStream.listen(_handleEvent);

    await webSocketManager.connect(_trackingChannel, orderId, token);
  }

  @override
  Future<void> disconnect() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await webSocketManager.disconnect(_trackingChannel);
  }

  /// Handles incoming WebSocket events and routes them to appropriate streams.
  void _handleEvent(WebSocketEvent event) {
    switch (event) {
      case LocationUpdateEvent():
        final location = WorkerLocation(
          latitude: event.latitude,
          longitude: event.longitude,
          heading: event.heading,
          eta: event.eta,
        );
        if (!_locationController.isClosed) {
          _locationController.add(location);
        }
      case StatusChangeEvent():
        final newStatus = OrderStatus.fromString(event.newStatus);
        if (!_statusController.isClosed) {
          _statusController.add(newStatus);
        }
      default:
        // Ignore non-tracking events
        break;
    }
  }

  /// Releases resources. Call when this data source is no longer needed.
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _locationController.close();
    await _statusController.close();
  }
}
