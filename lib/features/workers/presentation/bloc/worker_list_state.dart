part of 'worker_list_bloc.dart';

/// Sealed class representing all worker list states.
///
/// The [WorkerListBloc] emits these states in response to [WorkerListEvent]s,
/// driving the UI to display the appropriate content or feedback.
sealed class WorkerListState extends Equatable {
  const WorkerListState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any worker fetch has been triggered.
class WorkerListInitial extends WorkerListState {
  const WorkerListInitial();
}

/// State emitted while the first page of workers is being loaded.
///
/// The UI should display a loading indicator when in this state.
class WorkerListLoading extends WorkerListState {
  const WorkerListLoading();
}

/// State emitted when workers have been successfully loaded.
///
/// Contains the current list of workers, active filter, and pagination info.
class WorkerListLoaded extends WorkerListState {
  /// Creates a [WorkerListLoaded] state with the given data.
  const WorkerListLoaded({
    required this.workers,
    required this.filter,
    required this.hasMore,
    this.isLoadingMore = false,
    this.currentPage = 1,
  });

  /// The list of workers currently loaded (accumulated across pages).
  final List<WorkerProfile> workers;

  /// The currently active filter and sort configuration.
  final WorkerFilter filter;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// Whether additional pages are currently being loaded.
  final bool isLoadingMore;

  /// The current page number.
  final int currentPage;

  /// Creates a copy of this state with the given fields replaced.
  WorkerListLoaded copyWith({
    List<WorkerProfile>? workers,
    WorkerFilter? filter,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
  }) {
    return WorkerListLoaded(
      workers: workers ?? this.workers,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        workers,
        filter,
        hasMore,
        isLoadingMore,
        currentPage,
      ];
}

/// State emitted when a worker list operation fails.
///
/// Contains the [Failure] describing what went wrong, enabling the UI
/// to display appropriate error messages.
class WorkerListError extends WorkerListState {
  /// Creates a [WorkerListError] state with the given [failure].
  const WorkerListError({required this.failure});

  /// The failure describing what went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
