/// WebSocket event definitions for real-time communication.
///
/// Defines a sealed hierarchy of events received via WebSocket connections
/// for tracking, order status, purchases, and chat features.
///
/// Requirements: 9.3, 9.4, 10.8, 11.2, 11.4, 11.5
library;

/// Base sealed class for all WebSocket events.
///
/// Each subclass represents a specific real-time event type received
/// from the server via WebSocket channels.
sealed class WebSocketEvent {
  const WebSocketEvent();

  /// Creates a [WebSocketEvent] from a raw JSON map received via WebSocket.
  ///
  /// The [type] field determines which subclass to instantiate.
  /// Returns `null` if the event type is unrecognized.
  static WebSocketEvent? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final data = json['data'] as Map<String, dynamic>? ?? json;

    switch (type) {
      case 'location_update':
        return LocationUpdateEvent.fromJson(data);
      case 'status_change':
        return StatusChangeEvent.fromJson(data);
      case 'new_purchase':
        return NewPurchaseEvent.fromJson(data);
      case 'purchase_status_change':
        return PurchaseStatusChangeEvent.fromJson(data);
      case 'new_message':
        return NewMessageEvent.fromJson(data);
      case 'typing':
        return TypingEvent.fromJson(data);
      case 'message_read':
        return MessageReadEvent.fromJson(data);
      default:
        return null;
    }
  }
}

/// Emitted when a worker's location is updated during tracking.
///
/// Contains the worker's current GPS coordinates, heading, and ETA.
/// Requirement: 9.3
class LocationUpdateEvent extends WebSocketEvent {
  const LocationUpdateEvent({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.eta,
    this.orderId,
  });

  /// Creates a [LocationUpdateEvent] from a JSON map.
  factory LocationUpdateEvent.fromJson(Map<String, dynamic> json) {
    return LocationUpdateEvent(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble(),
      eta: json['eta'] as int?,
      orderId: json['order_id'] as String?,
    );
  }

  /// Worker's current latitude.
  final double latitude;

  /// Worker's current longitude.
  final double longitude;

  /// Worker's heading/bearing in degrees (0-360), or null if unavailable.
  final double? heading;

  /// Estimated time of arrival in minutes, or null if not yet calculated.
  final int? eta;

  /// The order ID this location update belongs to.
  final String? orderId;
}

/// Emitted when an order's status changes.
///
/// Requirement: 9.4
class StatusChangeEvent extends WebSocketEvent {
  const StatusChangeEvent({
    required this.orderId,
    required this.oldStatus,
    required this.newStatus,
  });

  /// Creates a [StatusChangeEvent] from a JSON map.
  factory StatusChangeEvent.fromJson(Map<String, dynamic> json) {
    return StatusChangeEvent(
      orderId: json['order_id'] as String? ?? '',
      oldStatus: json['old_status'] as String? ?? '',
      newStatus: json['new_status'] as String? ?? '',
    );
  }

  /// The order whose status changed.
  final String orderId;

  /// The previous status value.
  final String oldStatus;

  /// The new status value.
  final String newStatus;
}

/// Emitted when a worker submits a new purchase for approval.
///
/// Requirement: 10.8
class NewPurchaseEvent extends WebSocketEvent {
  const NewPurchaseEvent({required this.purchaseData});

  /// Creates a [NewPurchaseEvent] from a JSON map.
  factory NewPurchaseEvent.fromJson(Map<String, dynamic> json) {
    return NewPurchaseEvent(purchaseData: json);
  }

  /// Raw purchase data from the server.
  final Map<String, dynamic> purchaseData;
}

/// Emitted when a purchase's status changes (approved, rejected, etc.).
///
/// Requirement: 10.8
class PurchaseStatusChangeEvent extends WebSocketEvent {
  const PurchaseStatusChangeEvent({
    required this.purchaseId,
    required this.newStatus,
    this.orderId,
  });

  /// Creates a [PurchaseStatusChangeEvent] from a JSON map.
  factory PurchaseStatusChangeEvent.fromJson(Map<String, dynamic> json) {
    return PurchaseStatusChangeEvent(
      purchaseId: json['purchase_id'] as String? ?? '',
      newStatus: json['new_status'] as String? ?? '',
      orderId: json['order_id'] as String?,
    );
  }

  /// The purchase whose status changed.
  final String purchaseId;

  /// The new purchase status.
  final String newStatus;

  /// The order this purchase belongs to.
  final String? orderId;
}

/// Emitted when a new chat message is received.
///
/// Requirement: 11.4
class NewMessageEvent extends WebSocketEvent {
  const NewMessageEvent({required this.messageData});

  /// Creates a [NewMessageEvent] from a JSON map.
  factory NewMessageEvent.fromJson(Map<String, dynamic> json) {
    return NewMessageEvent(messageData: json);
  }

  /// Raw message data from the server.
  final Map<String, dynamic> messageData;
}

/// Emitted when a user starts or stops typing.
///
/// Requirement: 11.5
class TypingEvent extends WebSocketEvent {
  const TypingEvent({
    required this.userId,
    required this.isTyping,
    this.orderId,
  });

  /// Creates a [TypingEvent] from a JSON map.
  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    return TypingEvent(
      userId: json['user_id'] as String? ?? '',
      isTyping: json['is_typing'] as bool? ?? false,
      orderId: json['order_id'] as String?,
    );
  }

  /// The user who is typing.
  final String userId;

  /// Whether the user is currently typing.
  final bool isTyping;

  /// The order/chat context for this typing event.
  final String? orderId;
}

/// Emitted when messages are marked as read by the counterpart.
///
/// Requirement: 11.4
class MessageReadEvent extends WebSocketEvent {
  const MessageReadEvent({
    required this.messageIds,
    this.orderId,
  });

  /// Creates a [MessageReadEvent] from a JSON map.
  factory MessageReadEvent.fromJson(Map<String, dynamic> json) {
    final ids = json['message_ids'];
    return MessageReadEvent(
      messageIds: ids is List ? ids.cast<String>() : <String>[],
      orderId: json['order_id'] as String?,
    );
  }

  /// The IDs of messages that were read.
  final List<String> messageIds;

  /// The order/chat context for this read event.
  final String? orderId;
}
