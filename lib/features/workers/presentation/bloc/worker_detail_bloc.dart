import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/entities/worker_review.dart';
import '../../domain/repositories/worker_repository.dart';

part 'worker_detail_event.dart';
part 'worker_detail_state.dart';

/// BLoC responsible for managing the worker detail and reviews state.
///
/// Handles fetching a worker's full profile and paginated reviews.
///
/// Validates:
/// - Requirement 6.1: Display full worker profile info
/// - Requirement 6.2: Display worker's services list
/// - Requirement 6.3: Display up to 3 recent reviews
/// - Requirement 6.4: Display booking fee (Rp2.000)
/// - Requirement 6.5: Paginated reviews (10/page) with rating distribution
/// - Requirement 6.7: Error states with retry
/// - Requirement 6.8: Empty reviews state
@injectable
class WorkerDetailBloc extends Bloc<WorkerDetailEvent, WorkerDetailState> {
  /// Creates a [WorkerDetailBloc] with the required repository.
  WorkerDetailBloc({
    required WorkerRepository workerRepository,
  })  : _workerRepository = workerRepository,
        super(const WorkerDetailInitial()) {
    on<FetchWorkerDetail>(_onFetchWorkerDetail);
    on<FetchWorkerReviews>(_onFetchWorkerReviews);
    on<LoadMoreReviews>(_onLoadMoreReviews);
    on<FilterReviewsByStar>(_onFilterReviewsByStar);
  }

  final WorkerRepository _workerRepository;

  /// The number of reviews to load per page.
  static const int _reviewsPerPage = 10;

  /// Handles [FetchWorkerDetail] events.
  ///
  /// Fetches the full worker profile and the first 3 recent reviews.
  Future<void> _onFetchWorkerDetail(
    FetchWorkerDetail event,
    Emitter<WorkerDetailState> emit,
  ) async {
    emit(const WorkerDetailLoading());

    final result = await _workerRepository.getWorkerDetail(event.workerId);

    await result.fold(
      (failure) async => emit(WorkerDetailError(failure: failure)),
      (worker) async {
        // Also fetch the first 3 recent reviews
        final reviewsResult = await _workerRepository.getWorkerReviews(
          event.workerId,
          page: 1,
          perPage: 3,
        );

        final recentReviews = reviewsResult.fold(
          (_) => <WorkerReview>[],
          (reviews) => reviews,
        );

        emit(WorkerDetailLoaded(
          worker: worker,
          recentReviews: recentReviews,
        ));
      },
    );
  }

  /// Handles [FetchWorkerReviews] events.
  ///
  /// Fetches the first page of reviews for the reviews list page.
  Future<void> _onFetchWorkerReviews(
    FetchWorkerReviews event,
    Emitter<WorkerDetailState> emit,
  ) async {
    emit(const WorkerReviewsLoading());

    final result = await _workerRepository.getWorkerReviews(
      event.workerId,
      page: 1,
      perPage: _reviewsPerPage,
    );

    result.fold(
      (failure) => emit(WorkerReviewsError(failure: failure)),
      (reviews) => emit(WorkerReviewsLoaded(
        reviews: reviews,
        workerId: event.workerId,
        hasMore: reviews.length >= _reviewsPerPage,
        currentPage: 1,
        starFilter: null,
      )),
    );
  }

  /// Handles [LoadMoreReviews] events.
  ///
  /// Loads the next page of reviews and appends to the existing list.
  Future<void> _onLoadMoreReviews(
    LoadMoreReviews event,
    Emitter<WorkerDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkerReviewsLoaded) return;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;
    final result = await _workerRepository.getWorkerReviews(
      currentState.workerId,
      page: nextPage,
      perPage: _reviewsPerPage,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (reviews) => emit(currentState.copyWith(
        reviews: [...currentState.reviews, ...reviews],
        hasMore: reviews.length >= _reviewsPerPage,
        isLoadingMore: false,
        currentPage: nextPage,
      )),
    );
  }

  /// Handles [FilterReviewsByStar] events.
  ///
  /// Filters the displayed reviews by star rating.
  /// If [starRating] is null, shows all reviews.
  Future<void> _onFilterReviewsByStar(
    FilterReviewsByStar event,
    Emitter<WorkerDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkerReviewsLoaded) return;

    // Re-fetch from page 1 with the new filter
    emit(const WorkerReviewsLoading());

    final result = await _workerRepository.getWorkerReviews(
      currentState.workerId,
      page: 1,
      perPage: _reviewsPerPage,
    );

    result.fold(
      (failure) => emit(WorkerReviewsError(failure: failure)),
      (reviews) {
        // Apply star filter client-side
        final filteredReviews = event.starRating != null
            ? reviews
                .where((r) => r.rating == event.starRating)
                .toList()
            : reviews;

        emit(WorkerReviewsLoaded(
          reviews: filteredReviews,
          workerId: currentState.workerId,
          hasMore: reviews.length >= _reviewsPerPage,
          currentPage: 1,
          starFilter: event.starRating,
          allReviews: reviews,
        ));
      },
    );
  }
}
