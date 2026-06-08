import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:situkang_app/core/error/result.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/knowledge_entities.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../datasources/knowledge_remote_data_source.dart';

@LazySingleton(as: KnowledgeRepository)
class KnowledgeRepositoryImpl implements KnowledgeRepository {
  const KnowledgeRepositoryImpl(this.remoteDataSource);

  final KnowledgeRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<Article>>> getArticles({
    required int page,
    String? category,
  }) async {
    try {
      final articles = await remoteDataSource.getArticles(page: page, category: category);
      return Right(articles);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<Article>>> searchArticles(String query) async {
    try {
      final articles = await remoteDataSource.searchArticles(query);
      return Right(articles);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Article>> getArticleDetail(String id) async {
    try {
      final article = await remoteDataSource.getArticleDetail(id);
      return Right(article);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<Faq>>> getFaqs() async {
    try {
      final faqs = await remoteDataSource.getFaqs();
      return Right(faqs);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
