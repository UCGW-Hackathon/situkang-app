part of 'worker_history_bloc.dart';

sealed class WorkerHistoryEvent extends Equatable {
  const WorkerHistoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchWorkerHistory extends WorkerHistoryEvent {}

class LoadMoreWorkerHistory extends WorkerHistoryEvent {}

class FilterWorkerHistory extends WorkerHistoryEvent {
  const FilterWorkerHistory(this.filter);

  final String filter;

  @override
  List<Object?> get props => [filter];
}
