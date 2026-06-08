import 'package:dartz/dartz.dart' hide Order;
import 'package:injectable/injectable.dart' hide Order;
import 'package:situkang_app/core/error/result.dart';

import '../../../../core/error/failures.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/repositories/incoming_order_repository.dart';
import '../datasources/incoming_order_remote_data_source.dart';

@LazySingleton(as: IncomingOrderRepository)
class IncomingOrderRepositoryImpl implements IncomingOrderRepository {
  const IncomingOrderRepositoryImpl(this.remoteDataSource);

  final IncomingOrderRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<Order>>> getIncomingOrders() async {
    try {
      final orders = await remoteDataSource.getIncomingOrders();
      return Right(orders.map((m) => m.toEntity()).toList());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> acceptOrder({
    required String orderId,
    int? estimatedArrivalMinutes,
  }) async {
    try {
      await remoteDataSource.acceptOrder(orderId, estimatedArrivalMinutes);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> rejectOrder({
    required String orderId,
    required String reasonCode,
  }) async {
    try {
      await remoteDataSource.rejectOrder(orderId, reasonCode);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
