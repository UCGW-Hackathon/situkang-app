import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_data_source.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/user_model.dart';

/// Implementation of [ProfileRepository] with cache-first strategy.
///
/// For reads (getProfile): returns cached data immediately if available,
/// then fetches fresh data from the API and updates the cache.
/// For writes (update operations): calls the API first, then updates cache.
@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;

  @override
  Future<Result<User>> getProfile() async {
    try {
      final userModel = await remoteDataSource.getProfile();
      await localDataSource.cacheProfile(userModel);
      return Right(userModel.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<User>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    try {
      final userModel = await remoteDataSource.updateProfile(
        fullName: fullName,
        phone: phone,
        address: address,
      );
      // Update cache with the new profile data
      await localDataSource.cacheProfile(userModel);
      return Right(userModel.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<String>> updateAvatar(File imageFile) async {
    try {
      final avatarUrl = await remoteDataSource.updateAvatar(imageFile);
      // Update cached profile with new avatar URL
      await _updateCachedAvatar(avatarUrl);
      return Right(avatarUrl);
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<void>> updateLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      await remoteDataSource.updateLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      // Update cached profile with new location
      await _updateCachedLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  /// Updates the cached profile's avatar URL.
  Future<void> _updateCachedAvatar(String avatarUrl) async {
    final cached = await localDataSource.getCachedProfile();
    if (cached != null) {
      final updated = UserModel(
        userId: cached.userId,
        fullName: cached.fullName,
        email: cached.email,
        phone: cached.phone,
        role: cached.role,
        createdAt: cached.createdAt,
        avatarUrl: avatarUrl,
        address: cached.address,
        latitude: cached.latitude,
        longitude: cached.longitude,
        isActive: cached.isActive,
        emailVerifiedAt: cached.emailVerifiedAt,
        lastLoginAt: cached.lastLoginAt,
      );
      await localDataSource.cacheProfile(updated);
    }
  }

  /// Updates the cached profile's location fields.
  Future<void> _updateCachedLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final cached = await localDataSource.getCachedProfile();
    if (cached != null) {
      final updated = UserModel(
        userId: cached.userId,
        fullName: cached.fullName,
        email: cached.email,
        phone: cached.phone,
        role: cached.role,
        createdAt: cached.createdAt,
        avatarUrl: cached.avatarUrl,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isActive: cached.isActive,
        emailVerifiedAt: cached.emailVerifiedAt,
        lastLoginAt: cached.lastLoginAt,
      );
      await localDataSource.cacheProfile(updated);
    }
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

    final lowercaseMessage = message.toLowerCase();
    if (lowercaseMessage.contains('duplicate key') ||
        lowercaseMessage.contains('already exists') ||
        lowercaseMessage.contains('unique constraint') ||
        lowercaseMessage.contains('duplicate')) {
      if (lowercaseMessage.contains('phone')) {
        message = 'Nomor telepon sudah terdaftar, silakan gunakan nomor lain';
      } else if (lowercaseMessage.contains('email')) {
        message = 'Email sudah terdaftar, silakan gunakan email lain';
      } else {
        message = 'Data yang dimasukkan sudah terdaftar, silakan gunakan data lain';
      }
    }

    if (statusCode == 401 || statusCode == 403) {
      return AuthFailure(message);
    }

    return ServerFailure(message, statusCode: statusCode);
  }
}
