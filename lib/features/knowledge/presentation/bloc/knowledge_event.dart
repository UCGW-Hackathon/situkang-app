part of 'knowledge_bloc.dart';

sealed class KnowledgeEvent extends Equatable {
  const KnowledgeEvent();

  @override
  List<Object?> get props => [];
}

class FetchArticles extends KnowledgeEvent {}

class LoadMoreArticles extends KnowledgeEvent {}

class FilterArticles extends KnowledgeEvent {
  const FilterArticles(this.category);

  final String? category;

  @override
  List<Object?> get props => [category];
}

class SearchArticles extends KnowledgeEvent {
  const SearchArticles(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
