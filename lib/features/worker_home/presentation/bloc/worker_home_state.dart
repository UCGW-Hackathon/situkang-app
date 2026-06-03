part of 'worker_home_bloc.dart';

sealed class WorkerHomeState extends Equatable {
  const WorkerHomeState();

  @override
  List<Object?> get props => [];
}

class WorkerHomeInitial extends WorkerHomeState {}

class WorkerHomeLoading extends WorkerHomeState {}

class WorkerHomeLoaded extends WorkerHomeState {
  const WorkerHomeLoaded(this.dashboard, {this.actionError});

  final WorkerDashboard dashboard;
  final Failure? actionError;

  @override
  List<Object?> get props => [dashboard, actionError];
}

class WorkerHomeError extends WorkerHomeState {
  const WorkerHomeError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
