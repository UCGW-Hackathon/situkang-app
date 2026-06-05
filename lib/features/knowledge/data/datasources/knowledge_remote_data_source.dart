import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/knowledge_models.dart';

abstract class KnowledgeRemoteDataSource {
  Future<List<ArticleModel>> getArticles({
    required int page,
    String? category,
  });
  Future<List<ArticleModel>> searchArticles(String query);
  Future<ArticleModel> getArticleDetail(String id);
  Future<List<FaqModel>> getFaqs();
}

@LazySingleton(as: KnowledgeRemoteDataSource)
class KnowledgeRemoteDataSourceImpl implements KnowledgeRemoteDataSource {
  const KnowledgeRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<ArticleModel>> getArticles({
    required int page,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      if (category != null && category != 'all') 'category': category,
    };

    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.knowledgeArticles,
      queryParams: queryParams,
    );

    final apiResponse = ApiResponse<List<ArticleModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<List<ArticleModel>> searchArticles(String query) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/knowledge/articles/search',
      queryParams: {'q': query},
    );

    final apiResponse = ApiResponse<List<ArticleModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<ArticleModel> getArticleDetail(String id) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.knowledgeArticleDetail(id),
    );

    final apiResponse = ApiResponse<ArticleModel>.fromJson(response.data!, fromJsonT: (json) => ArticleModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<List<FaqModel>> getFaqs() async {
    final response = await apiClient.get<Map<String, dynamic>>(ApiEndpoints.knowledgeFaq);

    final apiResponse = ApiResponse<List<FaqModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }
}
