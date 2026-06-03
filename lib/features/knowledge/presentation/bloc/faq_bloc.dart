import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/knowledge_entities.dart';
import '../../domain/repositories/knowledge_repository.dart';

part 'faq_event.dart';
part 'faq_state.dart';

@injectable
class FaqBloc extends Bloc<FaqEvent, FaqState> {
  FaqBloc(this.repository) : super(const FaqState()) {
    on<FetchFaqs>(_onFetchFaqs);
  }

  final KnowledgeRepository repository;

  Future<void> _onFetchFaqs(
    FetchFaqs event,
    Emitter<FaqState> emit,
  ) async {
    emit(state.copyWith(status: FaqStatus.loading));

    final result = await repository.getFaqs();

    result.fold(
      (failure) => emit(state.copyWith(
        status: FaqStatus.error,
        failure: failure,
      )),
      (faqs) => emit(state.copyWith(
        status: FaqStatus.success,
        faqs: faqs,
      )),
    );
  }
}
