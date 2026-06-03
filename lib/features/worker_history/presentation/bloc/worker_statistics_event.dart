part of 'worker_statistics_bloc.dart';

sealed class WorkerStatisticsEvent extends Equatable {
  const WorkerStatisticsEvent();

  @override
  List<Object?> get props => [];
}

class FetchWorkerStatistics extends WorkerStatisticsEvent {
  const FetchWorkerStatistics(this.timeRange);

  final String timeRange;

  @override
  List<Object?> get props => [timeRange];
}
