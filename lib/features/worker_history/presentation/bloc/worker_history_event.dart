part of 'worker_history_bloc.dart';

sealed class WorkerHistoryEvent extends Equatable {
  const WorkerHistoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchWorkerHistory extends WorkerHistoryEvent {}

class LoadMoreWorkerHistory extends WorkerHistoryEvent {}

class FilterWorkerHistory extends WorkerHistoryEvent {
  const FilterWorkerHistory(this.status);

  final OrderStatus? status;

  @override
  List<Object?> get props => [status];
}
