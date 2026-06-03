part of 'worker_profile_bloc.dart';

sealed class WorkerProfileState extends Equatable {
  const WorkerProfileState();

  @override
  List<Object?> get props => [];
}

class WorkerProfileInitial extends WorkerProfileState {}

class WorkerProfileLoading extends WorkerProfileState {}

class WorkerProfileActionLoading extends WorkerProfileState {}

class WorkerProfileLoaded extends WorkerProfileState {
  const WorkerProfileLoaded(this.profile);

  final WorkerProfile profile;

  @override
  List<Object?> get props => [profile];
}

class WorkerProfileVerificationSubmitted extends WorkerProfileState {}

class WorkerProfileError extends WorkerProfileState {
  const WorkerProfileError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
