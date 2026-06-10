import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:situkang_app/core/error/result.dart';

import '../../../../core/error/failures.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../../domain/entities/worker_order_detail.dart';
import '../../domain/repositories/worker_order_repository.dart';
import '../datasources/worker_order_remote_data_source.dart';

@LazySingleton(as: WorkerOrderRepository)
class WorkerOrderRepositoryImpl implements WorkerOrderRepository {
  const WorkerOrderRepositoryImpl(this.remoteDataSource);

  final WorkerOrderRemoteDataSource remoteDataSource;

  @override
  Future<Result<WorkerOrderDetail>> getOrderDetail(String orderId) async {
    try {
      final detail = await remoteDataSource.getOrderDetail(orderId);
      return Right(detail.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await remoteDataSource.updateOrderStatus(orderId, status);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> uploadProgressPhoto({
    required String orderId,
    required String filePath,
    String? caption,
  }) async {
    try {
      await remoteDataSource.uploadProgressPhoto(orderId, filePath, caption);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> addWorkItem({
    required String orderId,
    required String itemName,
    required int cost,
    String? description,
  }) async {
    try {
      await remoteDataSource.addWorkItem(
        orderId: orderId,
        itemName: itemName,
        cost: cost,
        description: description,
      );
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<Invoice>> completeOrder({
    required String orderId,
    String? workerNotes,
  }) async {
    try {
      final invoice = await remoteDataSource.completeOrder(
        orderId,
        workerNotes,
      );
      return Right(invoice);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
