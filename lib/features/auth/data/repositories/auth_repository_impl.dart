import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementation of [AuthRepository] combining remote and local data sources.
///
/// Handles the orchestration between API calls and local token persistence:
/// - On login/register success: saves tokens via local data source
/// - On logout: calls API then clears local tokens
/// - On refresh: calls API, saves new tokens (token rotation)
/// - Maps [DioException] to appropriate [Failure] types
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  @override
  Future<Result<(User, Token)>> login({
    required String email,
    required String password,
  }) async {
    try {
      final (userModel, tokenModel) = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save tokens to secure storage on successful login
      await localDataSource.saveTokens(
        accessToken: tokenModel.accessToken,
        refreshToken: tokenModel.refreshToken,
      );

      return Right((userModel.toEntity(), tokenModel.toEntity()));
    } on DioException catch (e) {
      final failure = _mapDioException(e);
      if (failure is AuthFailure || e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        return const Left(AuthFailure('Email atau password salah'));
      }
      return Left(failure);
    } on Exception catch (e) {
      return Left(ServerFailure(
        e.toString(),
        statusCode: 0,
      ));
    }
  }

  @override
  Future<Result<(User, Token)>> register({
    required RegisterParams params,
  }) async {
    try {
      final (userModel, tokenModel) = await remoteDataSource.register(params);

      // Save tokens to secure storage on successful registration
      await localDataSource.saveTokens(
        accessToken: tokenModel.accessToken,
        refreshToken: tokenModel.refreshToken,
      );

      return Right((userModel.toEntity(), tokenModel.toEntity()));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(
        e.toString(),
        statusCode: 0,
      ));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Call API to invalidate refresh token on server
      await remoteDataSource.logout();

      // Clear local token storage regardless of API result
      await localDataSource.clearTokens();

      return const Right(null);
    } on DioException catch (e) {
      // Even if the API call fails, clear local tokens
      await localDataSource.clearTokens();

      // Still return success since local state is cleared
      // The server token will expire naturally
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return const Right(null);
      }

      return Left(_mapDioException(e));
    } on Exception {
      // Clear tokens even on unexpected errors
      await localDataSource.clearTokens();
      return const Right(null);
    }
  }

  @override
  Future<Result<Token>> refreshToken() async {
    try {
      final storedRefreshToken = await localDataSource.getRefreshToken();

      if (storedRefreshToken == null) {
        return const Left(AuthFailure(
          'Sesi telah berakhir, silakan login kembali',
          errorCode: 'NO_REFRESH_TOKEN',
        ));
      }

      final tokenModel = await remoteDataSource.refresh(
        refreshToken: storedRefreshToken,
      );

      // Save new tokens (token rotation)
      await localDataSource.saveTokens(
        accessToken: tokenModel.accessToken,
        refreshToken: tokenModel.refreshToken,
      );

      return Right(tokenModel.toEntity());
    } on DioException catch (e) {
      // If refresh fails with 401, the refresh token is expired/revoked
      if (e.response?.statusCode == 401) {
        await localDataSource.clearTokens();
        return const Left(AuthFailure(
          'Sesi telah berakhir, silakan login kembali',
          errorCode: 'REFRESH_TOKEN_EXPIRED',
        ));
      }

      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(
        e.toString(),
        statusCode: 0,
      ));
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String email}) async {
    try {
      await remoteDataSource.forgotPassword(email: email);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(
        e.toString(),
        statusCode: 0,
      ));
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        token: token,
        password: password,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(
        e.toString(),
        statusCode: 0,
      ));
    }
  }

  /// Maps a [DioException] to the appropriate [Failure] type.
  ///
  /// Follows the error mapping strategy defined in the design document:
  /// - 400 → ValidationFailure (field-level errors)
  /// - 401 → AuthFailure (invalid credentials or expired token)
  /// - 403 → AuthFailure (access denied)
  /// - 404/409/422/429/500+ → ServerFailure
  /// - Connection errors → NetworkFailure
  /// - Timeout → TimeoutFailure
  Failure _mapDioException(DioException e) {
    if (e.error is Failure) {
      return e.error as Failure;
    }
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
    final rawData = response.data;
    final Map<String, dynamic>? data = rawData is Map
        ? rawData.cast<String, dynamic>()
        : null;
    final message = data?['message'] as String? ?? 'Terjadi kesalahan';
    final errorCode = data?['error_code'] as String?;

    switch (statusCode) {
      case 400:
        final errors = _parseFieldErrors(data);
        if (errors.isNotEmpty) {
          return ValidationFailure(message, fieldErrors: errors);
        }
        return ServerFailure(message, statusCode: statusCode, errorCode: errorCode);

      case 401:
        return AuthFailure(message, errorCode: errorCode);

      case 403:
        return AuthFailure(message, errorCode: errorCode);

      case 409:
        // Conflict - e.g., duplicate email/phone during registration
        final errors = _parseFieldErrors(data);
        if (errors.isNotEmpty) {
          return ServerFailure(
            message,
            statusCode: statusCode,
            fieldErrors: errors
                .entries
                .map((e) => FieldError(field: e.key, message: e.value))
                .toList(),
            errorCode: errorCode,
          );
        }
        return ServerFailure(message, statusCode: statusCode, errorCode: errorCode);

      case 422:
        final errors = _parseFieldErrors(data);
        if (errors.isNotEmpty) {
          return ValidationFailure(message, fieldErrors: errors);
        }
        return ServerFailure(message, statusCode: statusCode, errorCode: errorCode);

      case 429:
        return ServerFailure(
          'Terlalu banyak permintaan, coba lagi nanti',
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
        return ServerFailure(message, statusCode: statusCode, errorCode: errorCode);
    }
  }

  /// Parses field-level validation errors from the API response.
  ///
  /// The API may return errors in different formats:
  /// - `{ "errors": { "email": ["The email has already been taken."] } }`
  /// - `{ "errors": [{ "field": "email", "message": "..." }] }`
  Map<String, String> _parseFieldErrors(Map<String, dynamic>? data) {
    if (data == null) return {};

    final errors = data['errors'];
    if (errors == null) return {};

    final fieldErrors = <String, String>{};

    if (errors is Map<String, dynamic>) {
      // Format: { "field_name": ["error message", ...] }
      for (final entry in errors.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          fieldErrors[entry.key] = (entry.value as List).first.toString();
        } else if (entry.value is String) {
          fieldErrors[entry.key] = entry.value as String;
        }
      }
    } else if (errors is List) {
      // Format: [{ "field": "email", "message": "..." }]
      for (final error in errors) {
        if (error is Map<String, dynamic>) {
          final field = error['field'] as String?;
          final message = error['message'] as String?;
          if (field != null && message != null) {
            fieldErrors[field] = message;
          }
        }
      }
    }

    return fieldErrors;
  }
}
