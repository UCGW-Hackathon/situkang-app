import 'package:dartz/dartz.dart' hide Order;
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/create_order_params.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_detail.dart';
import '../../domain/entities/order_filter.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_data_source.dart';
import '../datasources/order_remote_data_source.dart';

/// Implementation of [OrderRepository] with caching strategy.
///
/// For list views (getOrders): fetches from API first, caches results.
/// For detail views (getOrderDetail): returns cached data on network failure.
/// For mutations (createOrder, cancelOrder): always goes to API.
@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final OrderRemoteDataSource remoteDataSource;
  final OrderLocalDataSource localDataSource;

  @override
  Future<Result<Order>> createOrder(CreateOrderParams params) async {
    try {
      final orderModel = await remoteDataSource.createOrder(params);
      return Right(orderModel.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<(List<Order>, PaginationMeta)>> getOrders({
    OrderFilter? filter,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final (orderModels, meta) = await remoteDataSource.getOrders(
        filter: filter,
        page: page,
        perPage: perPage,
      );

      final orders = orderModels.map((m) => m.toEntity()).toList();

      // Cache the results
      final cacheKey = _buildCacheKey(filter, page, perPage);
      await localDataSource.cacheOrders(cacheKey, orderModels);

      return Right((orders, meta));
    } on DioException catch (e) {
      // Try to return cached data on network failure
      final cacheKey = _buildCacheKey(filter, page, perPage);
      final cached = await localDataSource.getCachedOrders(cacheKey);
      if (cached != null) {
        return Right((
          cached.map((m) => m.toEntity()).toList(),
          PaginationMeta(
            currentPage: page,
            perPage: perPage,
            total: cached.length,
            totalPages: 1,
          ),
        ));
      }
      return Left(_mapDioExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<OrderDetail>> getOrderDetail(String orderId) async {
    try {
      final orderDetailModel = await remoteDataSource.getOrderDetail(orderId);
      // Cache the detail
      await localDataSource.cacheOrderDetail(orderDetailModel);
      return Right(orderDetailModel.toEntity());
    } on DioException catch (e) {
      // On network failure, try to return cached data
      final cached = await localDataSource.getCachedOrderDetail(orderId);
      if (cached != null) {
        return Right(cached.toEntity());
      }
      return Left(_mapDioExceptionToFailure(e));
    } catch (e) {
      // On other failures, try cache as fallback
      final cached = await localDataSource.getCachedOrderDetail(orderId);
      if (cached != null) {
        return Right(cached.toEntity());
      }
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Order>> cancelOrder(
    String orderId, {
    required String cancelReason,
    String? notes,
  }) async {
    try {
      final orderModel = await remoteDataSource.cancelOrder(
        orderId,
        cancelReason: cancelReason,
        notes: notes,
      );
      // Invalidate cached detail since status changed
      await localDataSource.clearCache();
      return Right(orderModel.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  /// Builds a cache key based on the filter and pagination parameters.
  String _buildCacheKey(OrderFilter? filter, int page, int perPage) {
    final parts = <String>['p_$page', 'pp_$perPage'];

    if (filter?.status != null) {
      parts.add('status_${filter!.status!.value}');
    }

    return parts.join('_');
  }

  /// Maps [DioException] to typed [Failure] objects.
  Failure _mapDioExceptionToFailure(DioException exception) {
    if (exception.error is Failure) {
      return exception.error as Failure;
    }
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
      return ServerFailure('Pesanan tidak ditemukan', statusCode: statusCode);
    }

    if (statusCode == 422) {
      return ServerFailure(message, statusCode: statusCode);
    }

    return ServerFailure(message, statusCode: statusCode);
  }
}
