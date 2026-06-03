import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/knowledge_entities.dart';
import '../../domain/repositories/knowledge_repository.dart';

part 'knowledge_event.dart';
part 'knowledge_state.dart';

@injectable
class KnowledgeBloc extends Bloc<KnowledgeEvent, KnowledgeState> {
  KnowledgeBloc(this.repository) : super(const KnowledgeState()) {
    on<FetchArticles>(_onFetchArticles);
    on<LoadMoreArticles>(_onLoadMoreArticles);
    on<FilterArticles>(_onFilterArticles);
    on<SearchArticles>(_onSearchArticles);
  }

  final KnowledgeRepository repository;

  Future<void> _onFetchArticles(
    FetchArticles event,
    Emitter<KnowledgeState> emit,
  ) async {
    emit(state.copyWith(status: KnowledgeStatus.loading, page: 1, isSearch: false));

    final result = await repository.getArticles(
      page: 1,
      category: state.filterCategory,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: KnowledgeStatus.error,
        failure: failure,
      )),
      (articles) => emit(state.copyWith(
        status: KnowledgeStatus.success,
        articles: articles,
        hasReachedMax: articles.isEmpty,
      )),
    );
  }

  Future<void> _onLoadMoreArticles(
    LoadMoreArticles event,
    Emitter<KnowledgeState> emit,
  ) async {
    if (state.hasReachedMax || state.status == KnowledgeStatus.loading || state.isSearch) return;

    final nextPage = state.page + 1;
    final result = await repository.getArticles(
      page: nextPage,
      category: state.filterCategory,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: KnowledgeStatus.error,
        failure: failure,
      )),
      (articles) {
        emit(articles.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                status: KnowledgeStatus.success,
                articles: List.of(state.articles)..addAll(articles),
                page: nextPage,
                hasReachedMax: false,
              ));
      },
    );
  }

  Future<void> _onFilterArticles(
    FilterArticles event,
    Emitter<KnowledgeState> emit,
  ) async {
    emit(state.copyWith(filterCategory: event.category, searchQuery: ''));
    add(FetchArticles());
  }

  Future<void> _onSearchArticles(
    SearchArticles event,
    Emitter<KnowledgeState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(searchQuery: '', isSearch: false));
      add(FetchArticles());
      return;
    }

    if (query.length < 2) return; // Search requires min 2 chars as per specs

    emit(state.copyWith(status: KnowledgeStatus.loading, searchQuery: query, isSearch: true));

    final result = await repository.searchArticles(query);

    result.fold(
      (failure) => emit(state.copyWith(
        status: KnowledgeStatus.error,
        failure: failure,
      )),
      (articles) => emit(state.copyWith(
        status: KnowledgeStatus.success,
        articles: articles,
        hasReachedMax: true, // Search results don't paginate in this implementation
      )),
    );
  }
}
