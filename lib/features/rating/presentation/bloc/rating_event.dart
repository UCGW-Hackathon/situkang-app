part of 'rating_bloc.dart';

sealed class RatingEvent extends Equatable {
  const RatingEvent();

  @override
  List<Object?> get props => [];
}

class CheckExistingRating extends RatingEvent {
  const CheckExistingRating({required this.orderId});

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class SubmitRating extends RatingEvent {
  const SubmitRating({
    required this.orderId,
    required this.workerId,
    required this.score,
    this.comment,
    this.tags = const [],
  });

  final String orderId;
  final String workerId;
  final int score;
  final String? comment;
  final List<String> tags;

  @override
  List<Object?> get props => [orderId, workerId, score, comment, tags];
}
