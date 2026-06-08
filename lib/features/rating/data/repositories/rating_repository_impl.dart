import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:situkang_app/core/error/result.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';
import '../datasources/rating_remote_data_source.dart';

@LazySingleton(as: RatingRepository)
class RatingRepositoryImpl implements RatingRepository {
  const RatingRepositoryImpl(this.remoteDataSource);

  final RatingRemoteDataSource remoteDataSource;

  @override
  Future<Result<Rating>> submitRating({
    required String orderId,
    required String workerId,
    required int score,
    String? comment,
    List<String> tags = const [],
  }) async {
    try {
      final rating = await remoteDataSource.submitRating(
        orderId: orderId,
        workerId: workerId,
        score: score,
        comment: comment,
        tags: tags,
      );
      return Right(rating);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Rating?>> getRatingByOrder({required String orderId}) async {
    try {
      final rating = await remoteDataSource.getRatingByOrder(orderId);
      return Right(rating);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<Rating>>> getWorkerReviews({
    required String workerId,
    int page = 1,
    int limit = 10,
    int? filterScore,
  }) async {
    try {
      final reviews = await remoteDataSource.getWorkerReviews(
        workerId,
        page: page,
        limit: limit,
        filterScore: filterScore,
      );
      return Right(reviews);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
