import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:situkang_app/core/error/result.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/worker_dashboard.dart';
import '../../domain/repositories/worker_home_repository.dart';
import '../datasources/worker_home_remote_data_source.dart';

@LazySingleton(as: WorkerHomeRepository)
class WorkerHomeRepositoryImpl implements WorkerHomeRepository {
  const WorkerHomeRepositoryImpl(this.remoteDataSource);

  final WorkerHomeRemoteDataSource remoteDataSource;

  @override
  Future<Result<WorkerDashboard>> getDashboardData() async {
    try {
      final dashboard = await remoteDataSource.getDashboardData();
      return Right(dashboard);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> toggleAvailability({required bool isAvailable}) async {
    try {
      final newState = await remoteDataSource.toggleAvailability(
        isAvailable: isAvailable,
      );
      return Right(newState);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
