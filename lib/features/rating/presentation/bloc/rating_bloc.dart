import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';

part 'rating_event.dart';
part 'rating_state.dart';

@injectable
class RatingBloc extends Bloc<RatingEvent, RatingState> {
  RatingBloc(this.repository) : super(RatingInitial()) {
    on<CheckExistingRating>(_onCheckExistingRating);
    on<SubmitRating>(_onSubmitRating);
  }

  final RatingRepository repository;

  Future<void> _onCheckExistingRating(
    CheckExistingRating event,
    Emitter<RatingState> emit,
  ) async {
    emit(RatingLoading());

    final result = await repository.getRatingByOrder(orderId: event.orderId);

    result.fold(
      (failure) => emit(RatingError(failure)),
      (rating) {
        if (rating != null) {
          emit(RatingSubmitted(rating));
        } else {
          // No existing rating, we are ready to take input
          emit(RatingReady());
        }
      },
    );
  }

  Future<void> _onSubmitRating(
    SubmitRating event,
    Emitter<RatingState> emit,
  ) async {
    emit(RatingSubmitting());

    final result = await repository.submitRating(
      orderId: event.orderId,
      workerId: event.workerId,
      score: event.score,
      comment: event.comment,
      tags: event.tags,
    );

    result.fold(
      (failure) => emit(RatingSubmitError(failure)),
      (rating) => emit(RatingSubmitted(rating)),
    );
  }
}
