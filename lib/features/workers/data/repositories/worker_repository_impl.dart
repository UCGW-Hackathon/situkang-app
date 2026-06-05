import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/worker_filter.dart';
import '../../domain/entities/worker_list_result.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/entities/worker_review.dart';
import '../../domain/repositories/worker_repository.dart';
import '../datasources/worker_local_data_source.dart';
import '../datasources/worker_remote_data_source.dart';

/// Implementation of [WorkerRepository] with cache-first strategy for detail views.
///
/// For list views (getNearbyWorkers): fetches from API first, caches results.
/// For detail views (getWorkerDetail): returns cached data on network failure.
/// For reviews (getWorkerReviews): fetches from API first, caches results.
@LazySingleton(as: WorkerRepository)
class WorkerRepositoryImpl implements WorkerRepository {
  const WorkerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final WorkerRemoteDataSource remoteDataSource;
  final WorkerLocalDataSource localDataSource;

  /// User's current latitude for nearby worker queries.
  ///
  /// Defaults to Jakarta when the app has not resolved a profile/device
  /// location yet, so dependency injection can construct the repository.
  double get latitude => -6.200000;

  /// User's current longitude for nearby worker queries.
  double get longitude => 106.816666;

  @override
  Future<Result<WorkerListResult>> getNearbyWorkers({
    WorkerFilter? filter,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final (workerModels, meta) = await remoteDataSource.getNearbyWorkers(
        latitude: latitude,
        longitude: longitude,
        filter: filter,
        page: page,
        perPage: perPage,
      );

      final workers = workerModels.map((m) => m.toEntity()).toList();

      // Cache the results
      final cacheKey = _buildCacheKey(filter, page, perPage);
      await localDataSource.cacheNearbyWorkers(cacheKey, workerModels);

      return Right(WorkerListResult(
        workers: workers,
        paginationMeta: meta,
      ));
    } on DioException catch (e) {
      // Try to return cached data on network failure
      final cacheKey = _buildCacheKey(filter, page, perPage);
      final cached = await localDataSource.getCachedNearbyWorkers(cacheKey);
      if (cached != null) {
        return Right(WorkerListResult(
          workers: cached.map((m) => m.toEntity()).toList(),
          paginationMeta: PaginationMeta(
            currentPage: page,
            perPage: perPage,
            total: cached.length,
            totalPages: 1,
          ),
        ));
      }
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<(WorkerProfile, List<WorkerReview>)>> getWorkerDetail(
      String workerId) async {
    try {
      final (workerModel, topReviewModels) =
          await remoteDataSource.getWorkerDetail(workerId);
      // Cache the detail (worker only)
      await localDataSource.cacheWorkerDetail(workerModel);
      final worker = workerModel.toEntity();
      final topReviews = topReviewModels.map((m) => m.toEntity()).toList();
      return Right((worker, topReviews));
    } on DioException catch (e) {
      // On network failure, try to return cached data (with empty reviews)
      final cached = await localDataSource.getCachedWorkerDetail(workerId);
      if (cached != null) {
        return Right((cached.toEntity(), <WorkerReview>[]));
      }
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      // On other failures, try cache as fallback
      final cached = await localDataSource.getCachedWorkerDetail(workerId);
      if (cached != null) {
        return Right((cached.toEntity(), <WorkerReview>[]));
      }
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<WorkerReview>>> getWorkerReviews(
    String workerId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final (reviewModels, _) = await remoteDataSource.getWorkerReviews(
        workerId,
        page: page,
        perPage: perPage,
      );

      final reviews = reviewModels.map((m) => m.toEntity()).toList();

      // Cache the reviews
      await localDataSource.cacheWorkerReviews(workerId, page, reviewModels);

      return Right(reviews);
    } on DioException catch (e) {
      // Try to return cached reviews on network failure
      final cached =
          await localDataSource.getCachedWorkerReviews(workerId, page);
      if (cached != null) {
        return Right(cached.map((m) => m.toEntity()).toList());
      }
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      // On other failures, try cache as fallback
      final cached =
          await localDataSource.getCachedWorkerReviews(workerId, page);
      if (cached != null) {
        return Right(cached.map((m) => m.toEntity()).toList());
      }
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  /// Builds a cache key based on the filter and pagination parameters.
  String _buildCacheKey(WorkerFilter? filter, int page, int perPage) {
    final parts = <String>[
      'lat_${latitude.toStringAsFixed(3)}',
      'lng_${longitude.toStringAsFixed(3)}',
      'p_$page',
      'pp_$perPage',
    ];

    if (filter != null) {
      if (filter.categoryId != null) parts.add('cat_${filter.categoryId}');
      if (filter.serviceId != null) parts.add('svc_${filter.serviceId}');
      if (filter.minRating != null) parts.add('mr_${filter.minRating}');
      if (filter.maxDistance != null) parts.add('md_${filter.maxDistance}');
      parts.add('sort_${filter.sortBy.value}');
      if (filter.searchKeyword != null) {
        parts.add('q_${filter.searchKeyword}');
      }
    }

    return parts.join('_');
  }

  /// Maps [DioException] to typed [Failure] objects.
  Failure _mapDioExceptionToFailure(DioException exception) {
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout) {
      return const TimeoutFailure();
    }

    if (exception.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    final statusCode = exception.response?.statusCode ?? 500;
    final responseData = exception.response?.data;

    var message = 'Terjadi kesalahan pada server';
    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ?? message;
    }

    if (statusCode == 401 || statusCode == 403) {
      return AuthFailure(message);
    }

    if (statusCode == 404) {
      return ServerFailure('Tukang tidak ditemukan', statusCode: statusCode);
    }

    return ServerFailure(message, statusCode: statusCode);
  }
}
