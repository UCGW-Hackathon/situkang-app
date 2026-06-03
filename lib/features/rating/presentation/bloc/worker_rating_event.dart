part of 'worker_rating_bloc.dart';

sealed class WorkerRatingEvent extends Equatable {
  const WorkerRatingEvent();

  @override
  List<Object?> get props => [];
}

class FetchCustomerRating extends WorkerRatingEvent {
  const FetchCustomerRating(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class SubmitCustomerRating extends WorkerRatingEvent {
  const SubmitCustomerRating({
    required this.orderId,
    required this.rating,
    this.comment,
    this.tags = const [],
  });

  final String orderId;
  final double rating;
  final String? comment;
  final List<String> tags;

  @override
  List<Object?> get props => [orderId, rating, comment, tags];
}
