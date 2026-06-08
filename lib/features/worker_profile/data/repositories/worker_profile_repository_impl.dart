import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/repositories/worker_profile_repository.dart';
import '../datasources/worker_profile_remote_data_source.dart';

@LazySingleton(as: WorkerProfileRepository)
class WorkerProfileRepositoryImpl implements WorkerProfileRepository {
  const WorkerProfileRepositoryImpl(this.remoteDataSource);

  final WorkerProfileRemoteDataSource remoteDataSource;

  @override
  Future<Result<WorkerProfile>> getWorkerProfile() async {
    try {
      final profile = await remoteDataSource.getWorkerProfile();
      return Right(profile);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<WorkerProfile>> updateWorkerProfile({
    String? name,
    String? bio,
    String? specialization,
  }) async {
    try {
      final profile = await remoteDataSource.updateWorkerProfile(
        name,
        bio,
        specialization,
      );
      return Right(profile);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<WorkerProfile>> uploadCoverPhoto(String filePath) async {
    try {
      final profile = await remoteDataSource.uploadCoverPhoto(filePath);
      return Right(profile);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> submitVerification({
    required String ktpPath,
    required List<String> certificatePaths,
    String? selfiePath,
  }) async {
    try {
      await remoteDataSource.submitVerification(
        ktpPath: ktpPath,
        certificatePaths: certificatePaths,
        selfiePath: selfiePath,
      );
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<WorkerProfile>> addService({
    required String name,
    required int basePrice,
    required String priceUnit,
  }) async {
    try {
      final profile = await remoteDataSource.addService(
        name,
        basePrice,
        priceUnit,
      );
      return Right(profile);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<WorkerProfile>> removeService(String serviceId) async {
    try {
      final profile = await remoteDataSource.removeService(serviceId);
      return Right(profile);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
