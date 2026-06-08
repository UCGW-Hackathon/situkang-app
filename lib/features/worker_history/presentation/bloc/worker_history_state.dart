part of 'worker_history_bloc.dart';

enum WorkerHistoryStatus { initial, loading, success, error }

class WorkerHistoryState extends Equatable {
  const WorkerHistoryState({
    this.status = WorkerHistoryStatus.initial,
    this.orders = const <Order>[],
    this.hasReachedMax = false,
    this.statusFilter,
    this.page = 1,
    this.failure,
  });

  final WorkerHistoryStatus status;
  final List<Order> orders;
  final bool hasReachedMax;
  final OrderStatus? statusFilter;
  final int page;
  final Failure? failure;

  WorkerHistoryState copyWith({
    WorkerHistoryStatus? status,
    List<Order>? orders,
    bool? hasReachedMax,
    OrderStatus? statusFilter,
    bool clearStatusFilter = false,
    int? page,
    Failure? failure,
  }) {
    return WorkerHistoryState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      page: page ?? this.page,
      failure: failure, // null by default when copying
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        hasReachedMax,
        statusFilter,
        page,
        failure,
      ];
}
