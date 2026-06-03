import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/worker_rating_repository.dart';

part 'worker_rating_event.dart';
part 'worker_rating_state.dart';

@injectable
class WorkerRatingBloc extends Bloc<WorkerRatingEvent, WorkerRatingState> {
  WorkerRatingBloc(this.repository) : super(WorkerRatingInitial()) {
    on<FetchCustomerRating>(_onFetchCustomerRating);
    on<SubmitCustomerRating>(_onSubmitCustomerRating);
  }

  final WorkerRatingRepository repository;

  Future<void> _onFetchCustomerRating(
    FetchCustomerRating event,
    Emitter<WorkerRatingState> emit,
  ) async {
    emit(WorkerRatingLoading());

    final result = await repository.getCustomerRating(event.orderId);

    result.fold(
      (failure) => emit(WorkerRatingError(failure)),
      (rating) {
        if (rating != null) {
          emit(WorkerRatingLoaded(rating));
        } else {
          emit(WorkerRatingEmpty());
        }
      },
    );
  }

  Future<void> _onSubmitCustomerRating(
    SubmitCustomerRating event,
    Emitter<WorkerRatingState> emit,
  ) async {
    emit(WorkerRatingSubmitting());

    final result = await repository.submitCustomerRating(
      orderId: event.orderId,
      rating: event.rating,
      comment: event.comment,
      tags: event.tags,
    );

    result.fold(
      (failure) => emit(WorkerRatingError(failure)),
      (_) => emit(WorkerRatingSubmitted()),
    );
  }
}
