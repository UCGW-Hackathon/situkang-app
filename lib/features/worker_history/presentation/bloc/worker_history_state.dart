part of 'worker_history_bloc.dart';

enum WorkerHistoryStatus { initial, loading, success, error }

class WorkerHistoryState extends Equatable {
  const WorkerHistoryState({
    this.status = WorkerHistoryStatus.initial,
    this.orders = const <Order>[],
    this.hasReachedMax = false,
    this.filter = 'completed',
    this.page = 1,
    this.failure,
  });

  final WorkerHistoryStatus status;
  final List<Order> orders;
  final bool hasReachedMax;
  final String filter;
  final int page;
  final Failure? failure;

  WorkerHistoryState copyWith({
    WorkerHistoryStatus? status,
    List<Order>? orders,
    bool? hasReachedMax,
    String? filter,
    int? page,
    Failure? failure,
  }) {
    return WorkerHistoryState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      failure: failure, // null by default when copying
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        hasReachedMax,
        filter,
        page,
        failure,
      ];
}
