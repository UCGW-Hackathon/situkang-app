part of 'tracking_bloc.dart';

/// Sealed class representing all tracking events.
///
/// Events are dispatched from the UI layer or internal subscriptions
/// to trigger state changes in the [TrackingBloc].
sealed class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched when the user opens the tracking screen.
///
/// Initiates WebSocket connection and subscribes to location/status streams.
/// Validates: Requirement 9.1, 9.3
class StartTracking extends TrackingEvent {
  /// Creates a [StartTracking] event for the given [orderId].
  const StartTracking({required this.orderId});

  /// The order ID to start tracking.
  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// Event dispatched when the user leaves the tracking screen.
///
/// Disconnects WebSocket and cancels all subscriptions.
class StopTracking extends TrackingEvent {
  const StopTracking();
}

/// Event dispatched internally when a new location update is received.
///
/// Triggered by WebSocket location_update events or REST polling fallback.
/// Validates: Requirement 9.2, 9.3
class LocationUpdated extends TrackingEvent {
  /// Creates a [LocationUpdated] event with the new [location].
  const LocationUpdated({required this.location});

  /// The worker's updated location.
  final WorkerLocation location;

  @override
  List<Object?> get props => [location];
}

/// Event dispatched internally when the order status changes.
///
/// Triggered by WebSocket status_change events.
/// Validates: Requirement 9.4, 9.5, 9.9
class StatusChanged extends TrackingEvent {
  /// Creates a [StatusChanged] event with the [newStatus].
  const StatusChanged({required this.newStatus});

  /// The new order status.
  final OrderStatus newStatus;

  @override
  List<Object?> get props => [newStatus];
}
