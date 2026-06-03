part of 'worker_list_bloc.dart';

/// Sealed class representing all worker list events.
///
/// Events are dispatched from the UI layer to trigger state changes
/// in the [WorkerListBloc].
sealed class WorkerListEvent extends Equatable {
  const WorkerListEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched to fetch the initial list of nearby workers.
///
/// Resets pagination and loads the first page of workers.
/// Validates: Requirement 5.1 (display workers sorted by distance).
class FetchWorkers extends WorkerListEvent {
  const FetchWorkers();
}

/// Event dispatched when the user applies a filter (category, min rating).
///
/// Resets pagination and re-fetches workers with the new filter.
/// Validates: Requirements 5.2, 5.3.
class ApplyFilter extends WorkerListEvent {
  /// Creates an [ApplyFilter] event with the given [filter].
  const ApplyFilter({required this.filter});

  /// The updated filter to apply.
  final WorkerFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Event dispatched when the user changes the sort criterion.
///
/// Resets pagination and re-fetches workers with the new sort order.
/// Validates: Requirement 5.4.
class ChangeSort extends WorkerListEvent {
  /// Creates a [ChangeSort] event with the given [sortBy].
  const ChangeSort({required this.sortBy});

  /// The new sort criterion.
  final WorkerSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

/// Event dispatched when the user enters a search keyword.
///
/// Resets pagination and re-fetches workers matching the keyword.
/// Validates: Requirement 5.5.
class SearchWorkers extends WorkerListEvent {
  /// Creates a [SearchWorkers] event with the given [keyword].
  const SearchWorkers({required this.keyword});

  /// The search keyword for name, specialization, or service type.
  final String keyword;

  @override
  List<Object?> get props => [keyword];
}

/// Event dispatched when the user scrolls to the bottom of the list.
///
/// Loads the next page of workers (infinite scroll pagination).
/// Validates: Requirement 5.7.
class LoadMore extends WorkerListEvent {
  const LoadMore();
}
