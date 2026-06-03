part of 'worker_statistics_bloc.dart';

sealed class WorkerStatisticsState extends Equatable {
  const WorkerStatisticsState();

  @override
  List<Object?> get props => [];
}

class WorkerStatisticsInitial extends WorkerStatisticsState {}

class WorkerStatisticsLoading extends WorkerStatisticsState {}

class WorkerStatisticsLoaded extends WorkerStatisticsState {
  const WorkerStatisticsLoaded({
    required this.statistics,
    required this.timeRange,
  });

  final WorkerStatistics statistics;
  final String timeRange;

  @override
  List<Object?> get props => [statistics, timeRange];
}

class WorkerStatisticsError extends WorkerStatisticsState {
  const WorkerStatisticsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
