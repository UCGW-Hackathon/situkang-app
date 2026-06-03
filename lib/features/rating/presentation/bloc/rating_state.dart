part of 'rating_bloc.dart';

sealed class RatingState extends Equatable {
  const RatingState();

  @override
  List<Object?> get props => [];
}

class RatingInitial extends RatingState {}

class RatingLoading extends RatingState {}

class RatingReady extends RatingState {}

class RatingSubmitting extends RatingState {}

class RatingSubmitted extends RatingState {
  const RatingSubmitted(this.rating);

  final Rating rating;

  @override
  List<Object?> get props => [rating];
}

class RatingError extends RatingState {
  const RatingError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class RatingSubmitError extends RatingState {
  const RatingSubmitError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
