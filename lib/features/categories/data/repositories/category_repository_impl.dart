import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_data_source.dart';

/// Implementation of [CategoryRepository] using remote data source.
///
/// Handles the orchestration of API calls and maps errors to [Failure] types.
/// Sorts categories by display order and services alphabetically by name.
///
/// Validates:
/// - Requirement 4.1: Services sorted alphabetically by name (case-insensitive)
/// - Requirement 4.2: Categories sorted by display order ascending
/// - Requirement 4.5: Error for inactive/non-existent categories (404)
@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  /// Creates a [CategoryRepositoryImpl] with the given [remoteDataSource].
  const CategoryRepositoryImpl({required this.remoteDataSource});

  /// The remote data source for category API calls.
  final CategoryRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final models = await remoteDataSource.getCategories();

      // Convert to entities and sort by display order (ascending) per Requirement 4.2
      final categories = models.map((m) => m.toEntity()).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      return Right(categories);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<Service>>> getCategoryServices(String categoryId) async {
    try {
      final models = await remoteDataSource.getCategoryServices(categoryId);

      // Convert to entities and sort alphabetically by name (case-insensitive)
      // per Requirement 4.1
      final services = models.map((m) => m.toEntity()).toList()
        ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return Right(services);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  /// Maps a [DioException] to the appropriate [Failure] type.
  Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response);

      case DioExceptionType.cancel:
        return const NetworkFailure('Permintaan dibatalkan');

      default:
        return const NetworkFailure();
    }
  }

  /// Maps an HTTP status code response to the appropriate [Failure] type.
  Failure _mapStatusCode(Response<dynamic>? response) {
    if (response == null) {
      return const NetworkFailure();
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data as Map<String, dynamic>?;
    final message = data?['message'] as String? ?? 'Terjadi kesalahan';
    final errorCode = data?['error_code'] as String?;

    switch (statusCode) {
      case 401:
        return AuthFailure(message, errorCode: errorCode);

      case 403:
        return AuthFailure(message, errorCode: errorCode);

      case 404:
        // Category not found or inactive per Requirement 4.5
        return ServerFailure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );

      default:
        if (statusCode >= 500) {
          return ServerFailure(
            'Terjadi kesalahan pada server',
            statusCode: statusCode,
            errorCode: errorCode,
          );
        }
        return ServerFailure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
    }
  }
}
