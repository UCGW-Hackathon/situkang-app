import 'package:situkang_app/core/error/result.dart';

import '../entities/knowledge_entities.dart';

abstract class KnowledgeRepository {
  Future<Result<List<Article>>> getArticles({
    required int page,
    String? category,
  });

  Future<Result<List<Article>>> searchArticles(String query);

  Future<Result<Article>> getArticleDetail(String id);

  Future<Result<List<Faq>>> getFaqs();
}
