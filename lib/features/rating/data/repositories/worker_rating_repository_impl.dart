import 'package:situkang_app/core/error/result.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/worker_rating_repository.dart';
import '../datasources/worker_rating_remote_data_source.dart';

@LazySingleton(as: WorkerRatingRepository)
class WorkerRatingRepositoryImpl implements WorkerRatingRepository {
  const WorkerRatingRepositoryImpl(this.remoteDataSource);

  final WorkerRatingRemoteDataSource remoteDataSource;

  @override
  Future<Result<void>> submitCustomerRating({
    required String orderId,
    required double rating,
    String? comment,
    List<String> tags = const [],
  }) async {
    try {
      await remoteDataSource.submitCustomerRating(
        orderId: orderId,
        rating: rating,
        comment: comment,
        tags: tags,
      );
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Rating?>> getCustomerRating(String orderId) async {
    try {
      final rating = await remoteDataSource.getCustomerRating(orderId);
      return Right(rating);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
