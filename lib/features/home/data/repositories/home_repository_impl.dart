import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';
import '../datasources/home_remote_data_source.dart';

/// Implementation of [HomeRepository] with cache-first strategy.
///
/// For reads (getHomeData): fetches fresh data from the API and caches it.
/// On network failure, falls back to cached data if available.
@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;

  @override
  Future<Result<HomeData>> getHomeData() async {
    try {
      // Try to get fresh data from the API
      final homeDataModel = await remoteDataSource.getHomeData();
      // Cache the fresh data
      await localDataSource.cacheHomeData(homeDataModel);
      return Right(homeDataModel.toEntity());
    } on DioException catch (e) {
      // On network failure, try to return cached data
      final cachedModel = await localDataSource.getCachedHomeData();
      if (cachedModel != null) {
        return Right(cachedModel.toEntity());
      }
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      // On other failures, try cache as fallback
      final cachedModel = await localDataSource.getCachedHomeData();
      if (cachedModel != null) {
        return Right(cachedModel.toEntity());
      }
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
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

    return ServerFailure(message, statusCode: statusCode);
  }
}
