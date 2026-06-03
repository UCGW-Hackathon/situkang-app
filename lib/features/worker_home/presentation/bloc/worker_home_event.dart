part of 'worker_home_bloc.dart';

sealed class WorkerHomeEvent extends Equatable {
  const WorkerHomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchDashboardData extends WorkerHomeEvent {}

class ToggleAvailability extends WorkerHomeEvent {
  const ToggleAvailability({required this.isAvailable});

  final bool isAvailable;

  @override
  List<Object?> get props => [isAvailable];
}
