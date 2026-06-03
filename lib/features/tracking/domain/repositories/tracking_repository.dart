import '../../../../core/constants/enums.dart';
import '../../../../core/error/result.dart';
import '../entities/timeline_entry.dart';
import '../entities/worker_location.dart';

/// Abstract repository defining real-time order tracking operations.
///
/// Combines WebSocket (primary) for real-time location/status updates
/// with REST polling (fallback) when WebSocket is disconnected.
///
/// Requirements: 9.1, 9.2, 9.3, 9.4, 9.5
abstract class TrackingRepository {
  /// Starts tracking a specific order.
  ///
  /// Connects to the WebSocket tracking channel for real-time updates.
  /// On WebSocket disconnect, automatically falls back to REST polling
  /// every 10 seconds.
  ///
  /// [orderId] is the order to track.
  Future<Result<void>> startTracking(String orderId);

  /// Stops tracking the current order.
  ///
  /// Disconnects from the WebSocket tracking channel and stops any
  /// active polling timers.
  ///
  /// [orderId] is the order to stop tracking.
  Future<Result<void>> stopTracking(String orderId);

  /// Stream of worker location updates.
  ///
  /// Emits [WorkerLocation] whenever the worker's position changes,
  /// either via WebSocket events or REST polling fallback.
  Stream<WorkerLocation> get locationStream;

  /// Stream of order status changes.
  ///
  /// Emits [OrderStatus] whenever the order status transitions
  /// (e.g., on_the_way → arrived → in_progress → completed).
  Stream<OrderStatus> get statusStream;

  /// Fetches the worker's current location via REST endpoint (fallback).
  ///
  /// Used when WebSocket is disconnected to poll for location updates.
  /// [orderId] is the order being tracked.
  Future<Result<WorkerLocation>> getLocationFallback(String orderId);

  /// Fetches the order tracking timeline.
  ///
  /// Returns the list of timeline entries showing order progress steps
  /// with their completion status.
  /// [orderId] is the order to get the timeline for.
  Future<Result<List<TimelineEntry>>> getTrackingTimeline(String orderId);
}
