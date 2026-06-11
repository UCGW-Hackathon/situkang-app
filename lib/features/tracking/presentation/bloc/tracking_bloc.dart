import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/timeline_entry.dart';
import '../../domain/entities/worker_location.dart';
import '../../domain/repositories/tracking_repository.dart';

part 'tracking_event.dart';
part 'tracking_state.dart';

/// BLoC responsible for managing real-time order tracking state.
///
/// Subscribes to WebSocket location and status streams from the
/// [TrackingRepository]. On WebSocket disconnect, the repository
/// automatically falls back to REST polling every 10 seconds.
///
/// When the order status transitions to "completed", emits
/// [TrackingCompleted] so the UI can navigate away within 3 seconds.
///
/// Validates:
/// - Requirement 9.1: Display map with worker and user location
/// - Requirement 9.2: Display worker's moving location with ETA
/// - Requirement 9.3: Update worker position within 2 seconds of event
/// - Requirement 9.4: Update status and timeline within 2 seconds of event
/// - Requirement 9.5: Display order timeline with visual distinction
/// - Requirement 9.8: Fallback polling on WebSocket disconnect
/// - Requirement 9.9: Navigate to completion view within 3 seconds
@injectable
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  /// Creates a [TrackingBloc] with the required [trackingRepository].
  TrackingBloc({required TrackingRepository trackingRepository})
    : _trackingRepository = trackingRepository,
      super(const TrackingInitial()) {
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<LocationUpdated>(_onLocationUpdated);
    on<StatusChanged>(_onStatusChanged);
  }

  final TrackingRepository _trackingRepository;

  StreamSubscription<WorkerLocation>? _locationSubscription;
  StreamSubscription<OrderStatus>? _statusSubscription;
  String? _currentOrderId;

  /// Handles [StartTracking] events.
  ///
  /// Calls repository.startTracking, fetches the initial timeline,
  /// and subscribes to location and status streams.
  Future<void> _onStartTracking(
    StartTracking event,
    Emitter<TrackingState> emit,
  ) async {
    _currentOrderId = event.orderId;

    // Start tracking (connects WebSocket)
    final startResult = await _trackingRepository.startTracking(event.orderId);

    // Fetch initial timeline
    final timelineResult = await _trackingRepository.getTrackingTimeline(
      event.orderId,
    );

    final timeline = timelineResult.fold(
      (_) => <TimelineEntry>[],
      (entries) => entries,
    );
    final locationResult = await _trackingRepository.getLocationFallback(
      event.orderId,
    );
    final initialLocation = locationResult.fold(
      (_) => null,
      (location) => location,
    );

    // Determine initial status from timeline
    final initialStatus = _determineCurrentStatus(timeline);

    // Even if WebSocket connection failed, we still emit active state
    // (the repository handles fallback polling internally)
    startResult.fold(
      (failure) {
        // WebSocket failed but polling started — emit active state
        emit(
          TrackingActive(
            status: initialStatus,
            timeline: timeline,
            workerLocation: initialLocation,
            etaMinutes: initialLocation?.eta,
          ),
        );
      },
      (_) {
        emit(
          TrackingActive(
            status: initialStatus,
            timeline: timeline,
            workerLocation: initialLocation,
            etaMinutes: initialLocation?.eta,
          ),
        );
      },
    );

    // Subscribe to location stream
    await _locationSubscription?.cancel();
    _locationSubscription = _trackingRepository.locationStream.listen(
      (location) => add(LocationUpdated(location: location)),
    );

    // Subscribe to status stream
    await _statusSubscription?.cancel();
    _statusSubscription = _trackingRepository.statusStream.listen(
      (status) => add(StatusChanged(newStatus: status)),
    );
  }

  /// Handles [StopTracking] events.
  ///
  /// Cancels all subscriptions and stops tracking.
  Future<void> _onStopTracking(
    StopTracking event,
    Emitter<TrackingState> emit,
  ) async {
    await _cancelSubscriptions();

    if (_currentOrderId != null) {
      await _trackingRepository.stopTracking(_currentOrderId!);
      _currentOrderId = null;
    }
  }

  /// Handles [LocationUpdated] events.
  ///
  /// Updates the active state with the new worker location and ETA.
  /// Requirement 9.3: Must update within 2 seconds of receiving the event.
  void _onLocationUpdated(LocationUpdated event, Emitter<TrackingState> emit) {
    final currentState = state;
    if (currentState is TrackingActive) {
      emit(
        currentState.copyWith(
          workerLocation: event.location,
          etaMinutes: event.location.eta,
          clearEta: event.location.eta == null,
        ),
      );
    }
  }

  /// Handles [StatusChanged] events.
  ///
  /// Updates the active state with the new status and refreshes the timeline.
  /// If the new status is "completed", emits [TrackingCompleted].
  /// Requirement 9.4: Must update within 2 seconds of receiving the event.
  /// Requirement 9.9: Navigate to completion view on "completed" within 3s.
  Future<void> _onStatusChanged(
    StatusChanged event,
    Emitter<TrackingState> emit,
  ) async {
    // If completed, emit TrackingCompleted for navigation
    if (event.newStatus == OrderStatus.completed) {
      await _cancelSubscriptions();
      if (_currentOrderId != null) {
        await _trackingRepository.stopTracking(_currentOrderId!);
        _currentOrderId = null;
      }
      emit(const TrackingCompleted());
      return;
    }

    final currentState = state;
    if (currentState is TrackingActive) {
      // Update timeline to reflect new status
      final updatedTimeline = _updateTimeline(
        currentState.timeline,
        event.newStatus,
      );

      emit(
        currentState.copyWith(
          status: event.newStatus,
          timeline: updatedTimeline,
        ),
      );
    }
  }

  /// Determines the current order status from the timeline entries.
  OrderStatus _determineCurrentStatus(List<TimelineEntry> timeline) {
    // Find the last completed entry
    for (var i = timeline.length - 1; i >= 0; i--) {
      if (timeline[i].isCompleted) {
        return timeline[i].status;
      }
    }
    return OrderStatus.accepted;
  }

  /// Updates the timeline entries to mark steps up to [newStatus] as completed.
  List<TimelineEntry> _updateTimeline(
    List<TimelineEntry> currentTimeline,
    OrderStatus newStatus,
  ) {
    final statusOrder = [
      OrderStatus.accepted,
      OrderStatus.onTheWay,
      OrderStatus.arrived,
      OrderStatus.inProgress,
      OrderStatus.completed,
    ];

    final newStatusIndex = statusOrder.indexOf(newStatus);
    if (newStatusIndex == -1) return currentTimeline;

    return currentTimeline.map((entry) {
      final entryIndex = statusOrder.indexOf(entry.status);
      if (entryIndex == -1) return entry;

      if (entryIndex <= newStatusIndex) {
        return entry.copyWith(
          isCompleted: true,
          timestamp: entry.timestamp ?? DateTime.now(),
        );
      }
      return entry.copyWith(isCompleted: false);
    }).toList();
  }

  /// Cancels all active stream subscriptions.
  Future<void> _cancelSubscriptions() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _statusSubscription?.cancel();
    _statusSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    if (_currentOrderId != null) {
      await _trackingRepository.stopTracking(_currentOrderId!);
    }
    return super.close();
  }
}
