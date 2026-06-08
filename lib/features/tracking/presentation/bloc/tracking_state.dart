part of 'tracking_bloc.dart';

/// Sealed class representing all tracking states.
///
/// The [TrackingBloc] emits these states in response to [TrackingEvent]s,
/// driving the UI to display the appropriate tracking view.
sealed class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

/// The initial state before tracking has started.
///
/// The UI should display a loading indicator while connecting.
class TrackingInitial extends TrackingState {
  const TrackingInitial();
}

/// State emitted while actively tracking a worker's location.
///
/// Contains the worker's current location, order status, timeline,
/// and estimated time of arrival.
///
/// Validates: Requirements 9.1, 9.2, 9.5, 9.6
class TrackingActive extends TrackingState {
  /// Creates a [TrackingActive] state.
  const TrackingActive({
    required this.status, required this.timeline, this.workerLocation,
    this.etaMinutes,
  });

  /// The worker's current location, or null if not yet received.
  final WorkerLocation? workerLocation;

  /// The current order status.
  final OrderStatus status;

  /// The order progress timeline entries.
  final List<TimelineEntry> timeline;

  /// Estimated time of arrival in minutes, or null if calculating.
  ///
  /// Displayed as "8 min" or "Calculating" if null (Requirement 9.2).
  final int? etaMinutes;

  /// Creates a copy of this state with the given fields replaced.
  TrackingActive copyWith({
    WorkerLocation? workerLocation,
    OrderStatus? status,
    List<TimelineEntry>? timeline,
    int? etaMinutes,
    bool clearEta = false,
  }) {
    return TrackingActive(
      workerLocation: workerLocation ?? this.workerLocation,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
      etaMinutes: clearEta ? null : (etaMinutes ?? this.etaMinutes),
    );
  }

  @override
  List<Object?> get props => [workerLocation, status, timeline, etaMinutes];
}

/// State emitted when the order status transitions to "completed".
///
/// The UI should navigate to the completion view within 3 seconds.
/// Validates: Requirement 9.9
class TrackingCompleted extends TrackingState {
  const TrackingCompleted();
}

/// State emitted when a tracking error occurs.
///
/// Contains the [Failure] describing what went wrong.
class TrackingError extends TrackingState {
  /// Creates a [TrackingError] state with the given [failure].
  const TrackingError({required this.failure});

  /// The failure describing what went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
