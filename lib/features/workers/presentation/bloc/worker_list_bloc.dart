import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/worker_filter.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/repositories/worker_repository.dart';

part 'worker_list_event.dart';
part 'worker_list_state.dart';

/// BLoC responsible for managing the nearby workers list state.
///
/// Handles fetching workers with filters, sorting, searching, and
/// infinite scroll pagination (10 items per page).
///
/// Validates:
/// - Requirement 5.1: Display workers sorted by distance (ascending)
/// - Requirement 5.2: Filter by category
/// - Requirement 5.3: Filter by minimum rating
/// - Requirement 5.4: Sort by distance/rating/price/completed_jobs
/// - Requirement 5.5: Search by name, specialization, or service type
/// - Requirement 5.7: Infinite scroll pagination (10 per page)
/// - Requirement 5.8: Empty state when no workers match
/// - Requirement 5.9: Location unavailable state
@injectable
class WorkerListBloc extends Bloc<WorkerListEvent, WorkerListState> {
  /// Creates a [WorkerListBloc] with the required repository.
  WorkerListBloc({
    required WorkerRepository workerRepository,
  })  : _workerRepository = workerRepository,
        super(const WorkerListInitial()) {
    on<FetchWorkers>(_onFetchWorkers);
    on<ApplyFilter>(_onApplyFilter);
    on<ChangeSort>(_onChangeSort);
    on<SearchWorkers>(_onSearchWorkers);
    on<LoadMore>(_onLoadMore);
  }

  final WorkerRepository _workerRepository;

  /// The number of workers to load per page.
  static const int _perPage = 10;

  /// The current filter being applied.
  WorkerFilter _currentFilter = const WorkerFilter();

  /// Handles [FetchWorkers] events.
  ///
  /// Resets pagination and loads the first page of workers.
  Future<void> _onFetchWorkers(
    FetchWorkers event,
    Emitter<WorkerListState> emit,
  ) async {
    emit(const WorkerListLoading());

    final result = await _workerRepository.getNearbyWorkers(
      filter: _currentFilter,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      (failure) => emit(WorkerListError(failure: failure)),
      (workerListResult) => emit(WorkerListLoaded(
        workers: workerListResult.workers,
        filter: _currentFilter,
        hasMore: workerListResult.hasNextPage,
        currentPage: 1,
      )),
    );
  }

  /// Handles [ApplyFilter] events.
  ///
  /// Updates the current filter and re-fetches from page 1.
  Future<void> _onApplyFilter(
    ApplyFilter event,
    Emitter<WorkerListState> emit,
  ) async {
    _currentFilter = event.filter;
    emit(const WorkerListLoading());

    final result = await _workerRepository.getNearbyWorkers(
      filter: _currentFilter,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      (failure) => emit(WorkerListError(failure: failure)),
      (workerListResult) => emit(WorkerListLoaded(
        workers: workerListResult.workers,
        filter: _currentFilter,
        hasMore: workerListResult.hasNextPage,
        currentPage: 1,
      )),
    );
  }

  /// Handles [ChangeSort] events.
  ///
  /// Updates the sort criterion and re-fetches from page 1.
  /// Sort order: ascending for distance/price, descending for rating/completed_jobs.
  Future<void> _onChangeSort(
    ChangeSort event,
    Emitter<WorkerListState> emit,
  ) async {
    _currentFilter = _currentFilter.copyWith(sortBy: event.sortBy);
    emit(const WorkerListLoading());

    final result = await _workerRepository.getNearbyWorkers(
      filter: _currentFilter,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      (failure) => emit(WorkerListError(failure: failure)),
      (workerListResult) => emit(WorkerListLoaded(
        workers: workerListResult.workers,
        filter: _currentFilter,
        hasMore: workerListResult.hasNextPage,
        currentPage: 1,
      )),
    );
  }

  /// Handles [SearchWorkers] events.
  ///
  /// Updates the search keyword and re-fetches from page 1.
  /// Search is case-insensitive partial match on name, specialization, service type.
  Future<void> _onSearchWorkers(
    SearchWorkers event,
    Emitter<WorkerListState> emit,
  ) async {
    _currentFilter = _currentFilter.copyWith(
      searchKeyword: event.keyword,
    );

    // Clear search keyword if empty
    if (event.keyword.isEmpty) {
      _currentFilter = _currentFilter.clearFields(searchKeyword: true);
    }

    emit(const WorkerListLoading());

    final result = await _workerRepository.getNearbyWorkers(
      filter: _currentFilter,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      (failure) => emit(WorkerListError(failure: failure)),
      (workerListResult) => emit(WorkerListLoaded(
        workers: workerListResult.workers,
        filter: _currentFilter,
        hasMore: workerListResult.hasNextPage,
        currentPage: 1,
      )),
    );
  }

  /// Handles [LoadMore] events.
  ///
  /// Loads the next page and appends workers to the existing list.
  /// Only triggers if there are more pages and not already loading.
  Future<void> _onLoadMore(
    LoadMore event,
    Emitter<WorkerListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkerListLoaded) return;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;
    final result = await _workerRepository.getNearbyWorkers(
      filter: _currentFilter,
      page: nextPage,
      perPage: _perPage,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (workerListResult) => emit(WorkerListLoaded(
        workers: [...currentState.workers, ...workerListResult.workers],
        filter: _currentFilter,
        hasMore: workerListResult.hasNextPage,
        isLoadingMore: false,
        currentPage: nextPage,
      )),
    );
  }
}
