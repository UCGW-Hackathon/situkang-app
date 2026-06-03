part of 'knowledge_bloc.dart';

enum KnowledgeStatus { initial, loading, success, error }

class KnowledgeState extends Equatable {
  const KnowledgeState({
    this.status = KnowledgeStatus.initial,
    this.articles = const <Article>[],
    this.hasReachedMax = false,
    this.page = 1,
    this.filterCategory,
    this.searchQuery = '',
    this.isSearch = false,
    this.failure,
  });

  final KnowledgeStatus status;
  final List<Article> articles;
  final bool hasReachedMax;
  final int page;
  final String? filterCategory;
  final String searchQuery;
  final bool isSearch;
  final Failure? failure;

  KnowledgeState copyWith({
    KnowledgeStatus? status,
    List<Article>? articles,
    bool? hasReachedMax,
    int? page,
    String? filterCategory,
    String? searchQuery,
    bool? isSearch,
    Failure? failure,
  }) {
    return KnowledgeState(
      status: status ?? this.status,
      articles: articles ?? this.articles,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      filterCategory: filterCategory ?? this.filterCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearch: isSearch ?? this.isSearch,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
        status,
        articles,
        hasReachedMax,
        page,
        filterCategory,
        searchQuery,
        isSearch,
        failure,
      ];
}
