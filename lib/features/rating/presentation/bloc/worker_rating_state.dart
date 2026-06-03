part of 'worker_rating_bloc.dart';

sealed class WorkerRatingState extends Equatable {
  const WorkerRatingState();

  @override
  List<Object?> get props => [];
}

class WorkerRatingInitial extends WorkerRatingState {}

class WorkerRatingLoading extends WorkerRatingState {}

class WorkerRatingSubmitting extends WorkerRatingState {}

class WorkerRatingEmpty extends WorkerRatingState {}

class WorkerRatingLoaded extends WorkerRatingState {
  const WorkerRatingLoaded(this.rating);

  final Rating rating;

  @override
  List<Object?> get props => [rating];
}

class WorkerRatingSubmitted extends WorkerRatingState {}

class WorkerRatingError extends WorkerRatingState {
  const WorkerRatingError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
