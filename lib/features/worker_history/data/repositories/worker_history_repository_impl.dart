import 'package:dartz/dartz.dart' hide Order;
import 'package:injectable/injectable.dart' hide Order;
import 'package:situkang_app/core/error/result.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/constants/enums.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/worker_statistics.dart';
import '../../domain/repositories/worker_history_repository.dart';
import '../datasources/worker_history_remote_data_source.dart';

@LazySingleton(as: WorkerHistoryRepository)
class WorkerHistoryRepositoryImpl implements WorkerHistoryRepository {
  const WorkerHistoryRepositoryImpl(this.remoteDataSource);

  final WorkerHistoryRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<Order>>> getHistory({
    required OrderStatus? status,
    required int page,
  }) async {
    try {
      final history = await remoteDataSource.getHistory(status, page);
      return Right(history.map((m) => m.toEntity()).toList());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<WorkerStatistics>> getStatistics({
    required String timeRange,
  }) async {
    try {
      final stats = await remoteDataSource.getStatistics(timeRange);
      return Right(stats);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
