import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:situkang_app/core/error/result.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/worker_location.dart';
import '../../domain/repositories/location_sharing_repository.dart';
import '../datasources/location_sharing_remote_data_source.dart';
import '../models/worker_location_model.dart';

@LazySingleton(as: LocationSharingRepository)
class LocationSharingRepositoryImpl implements LocationSharingRepository {
  const LocationSharingRepositoryImpl(this.remoteDataSource);

  final LocationSharingRemoteDataSource remoteDataSource;

  @override
  Future<Result<void>> startSharing(String orderId) async {
    try {
      await remoteDataSource.startSharing(orderId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> stopSharing() async {
    try {
      await remoteDataSource.stopSharing();
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> sendLocationUpdate(WorkerLocation location) async {
    try {
      final model = WorkerLocationModel(
        latitude: location.latitude,
        longitude: location.longitude,
        heading: location.heading,
        speed: location.speed,
      );
      await remoteDataSource.sendLocationUpdate(model);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }
}
