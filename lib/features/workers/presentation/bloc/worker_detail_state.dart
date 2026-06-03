part of 'worker_detail_bloc.dart';

/// Sealed class representing all worker detail states.
///
/// The [WorkerDetailBloc] emits these states in response to [WorkerDetailEvent]s,
/// driving the UI to display the appropriate content or feedback.
sealed class WorkerDetailState extends Equatable {
  const WorkerDetailState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any worker detail fetch has been triggered.
class WorkerDetailInitial extends WorkerDetailState {
  const WorkerDetailInitial();
}

/// State emitted while the worker detail is being loaded.
class WorkerDetailLoading extends WorkerDetailState {
  const WorkerDetailLoading();
}

/// State emitted when the worker detail has been successfully loaded.
///
/// Contains the full worker profile and up to 3 recent reviews.
class WorkerDetailLoaded extends WorkerDetailState {
  /// Creates a [WorkerDetailLoaded] state with the given data.
  const WorkerDetailLoaded({
    required this.worker,
    this.recentReviews = const [],
  });

  /// The full worker profile.
  final WorkerProfile worker;

  /// Up to 3 most recent reviews for this worker.
  final List<WorkerReview> recentReviews;

  @override
  List<Object?> get props => [worker, recentReviews];
}

/// State emitted when the worker detail fails to load.
///
/// Validates: Requirement 6.7 (error state with retry).
class WorkerDetailError extends WorkerDetailState {
  /// Creates a [WorkerDetailError] state with the given [failure].
  const WorkerDetailError({required this.failure});

  /// The failure describing what went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// State emitted while the worker reviews list is being loaded.
class WorkerReviewsLoading extends WorkerDetailState {
  const WorkerReviewsLoading();
}

/// State emitted when the worker reviews have been successfully loaded.
///
/// Contains the paginated reviews list and pagination info.
class WorkerReviewsLoaded extends WorkerDetailState {
  /// Creates a [WorkerReviewsLoaded] state with the given data.
  const WorkerReviewsLoaded({
    required this.reviews,
    required this.workerId,
    required this.hasMore,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.starFilter,
    this.allReviews,
  });

  /// The list of reviews currently loaded.
  final List<WorkerReview> reviews;

  /// The worker ID these reviews belong to.
  final String workerId;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// The current page number.
  final int currentPage;

  /// Whether additional pages are currently being loaded.
  final bool isLoadingMore;

  /// The currently active star filter (null = all reviews).
  final int? starFilter;

  /// All reviews before filtering (used for rating distribution).
  final List<WorkerReview>? allReviews;

  /// Creates a copy of this state with the given fields replaced.
  WorkerReviewsLoaded copyWith({
    List<WorkerReview>? reviews,
    String? workerId,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    int? starFilter,
    List<WorkerReview>? allReviews,
  }) {
    return WorkerReviewsLoaded(
      reviews: reviews ?? this.reviews,
      workerId: workerId ?? this.workerId,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      starFilter: starFilter ?? this.starFilter,
      allReviews: allReviews ?? this.allReviews,
    );
  }

  @override
  List<Object?> get props => [
        reviews,
        workerId,
        hasMore,
        currentPage,
        isLoadingMore,
        starFilter,
        allReviews,
      ];
}

/// State emitted when the worker reviews fail to load.
class WorkerReviewsError extends WorkerDetailState {
  /// Creates a [WorkerReviewsError] state with the given [failure].
  const WorkerReviewsError({required this.failure});

  /// The failure describing what went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
