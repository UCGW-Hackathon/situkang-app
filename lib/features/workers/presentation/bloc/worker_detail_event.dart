part of 'worker_detail_bloc.dart';

/// Sealed class representing all worker detail events.
///
/// Events are dispatched from the UI layer to trigger state changes
/// in the [WorkerDetailBloc].
sealed class WorkerDetailEvent extends Equatable {
  const WorkerDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched to fetch the full worker profile and recent reviews.
///
/// Validates: Requirements 6.1, 6.2, 6.3, 6.4.
class FetchWorkerDetail extends WorkerDetailEvent {
  /// Creates a [FetchWorkerDetail] event with the given [workerId].
  ///
  /// [preloadedWorker] is optional partial data from the list view that can
  /// be displayed immediately while the full detail is being fetched.
  const FetchWorkerDetail({
    required this.workerId,
    this.preloadedWorker,
  });

  /// The ID of the worker to fetch details for.
  final String workerId;

  /// Optional partial worker data from the list for immediate display.
  final WorkerProfile? preloadedWorker;

  @override
  List<Object?> get props => [workerId, preloadedWorker];
}

/// Event dispatched to fetch the paginated reviews list for a worker.
///
/// Validates: Requirement 6.5.
class FetchWorkerReviews extends WorkerDetailEvent {
  /// Creates a [FetchWorkerReviews] event with the given [workerId].
  const FetchWorkerReviews({required this.workerId});

  /// The ID of the worker whose reviews to fetch.
  final String workerId;

  @override
  List<Object?> get props => [workerId];
}

/// Event dispatched to load the next page of reviews.
///
/// Validates: Requirement 6.5 (pagination).
class LoadMoreReviews extends WorkerDetailEvent {
  const LoadMoreReviews();
}

/// Event dispatched to filter reviews by star rating.
///
/// If [starRating] is null, all reviews are shown.
/// Validates: Requirement 6.5 (star filter).
class FilterReviewsByStar extends WorkerDetailEvent {
  /// Creates a [FilterReviewsByStar] event with the given [starRating].
  const FilterReviewsByStar({this.starRating});

  /// The star rating to filter by (1-5), or null for all reviews.
  final int? starRating;

  @override
  List<Object?> get props => [starRating];
}
