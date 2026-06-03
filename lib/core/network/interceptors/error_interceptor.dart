import 'dart:io';

import 'package:dio/dio.dart';

import '../../error/failures.dart';

/// Interceptor that maps HTTP errors and Dio exceptions to typed [Failure] objects.
///
/// Error mapping strategy:
/// - 400 → [ValidationFailure] with field-level errors
/// - 401 → [AuthFailure] (unauthorized)
/// - 403 → [AuthFailure] (forbidden)
/// - 404, 409, 422, 429, 500+ → [ServerFailure]
/// - Connection errors → [NetworkFailure]
/// - Timeout errors → [TimeoutFailure]
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = _mapDioExceptionToFailure(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: failure,
        message: failure.message,
      ),
    );
  }

  Failure _mapDioExceptionToFailure(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      case DioExceptionType.badResponse:
        return _mapStatusCodeToFailure(err.response);

      case DioExceptionType.cancel:
        return const ServerFailure(
          'Permintaan dibatalkan',
          statusCode: 0,
        );

      case DioExceptionType.badCertificate:
        return const ServerFailure(
          'Sertifikat keamanan tidak valid',
          statusCode: 0,
        );

      case DioExceptionType.unknown:
        if (err.error is SocketException) {
          return const NetworkFailure();
        }
        return const ServerFailure(
          'Terjadi kesalahan yang tidak diketahui',
          statusCode: 0,
        );
    }
  }

  Failure _mapStatusCodeToFailure(Response<dynamic>? response) {
    if (response == null) {
      return const NetworkFailure();
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    final message = _extractMessage(data) ?? _defaultMessageForStatus(statusCode);
    final errorCode = _extractErrorCode(data);

    switch (statusCode) {
      case 400:
        return ValidationFailure(
          message,
          fieldErrors: _extractFieldErrors(data),
        );

      case 401:
        return AuthFailure(message, errorCode: errorCode);

      case 403:
        return AuthFailure(message, errorCode: errorCode);

      case 404:
      case 409:
      case 422:
      case 429:
        return ServerFailure(
          message,
          statusCode: statusCode,
          fieldErrors: _extractServerFieldErrors(data),
          errorCode: errorCode,
        );

      default:
        if (statusCode >= 500) {
          return ServerFailure(
            message,
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

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }

  String? _extractErrorCode(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['error_code'] as String? ?? data['code'] as String?;
    }
    return null;
  }

  Map<String, String> _extractFieldErrors(dynamic data) {
    final fieldErrors = <String, String>{};
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        for (final entry in errors.entries) {
          if (entry.value is String) {
            fieldErrors[entry.key] = entry.value as String;
          } else if (entry.value is List && (entry.value as List).isNotEmpty) {
            fieldErrors[entry.key] = (entry.value as List).first.toString();
          }
        }
      }
    }
    return fieldErrors;
  }

  List<FieldError>? _extractServerFieldErrors(dynamic data) {
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is List) {
        return errors
            .whereType<Map<String, dynamic>>()
            .map(FieldError.fromJson)
            .toList();
      }
      if (errors is Map<String, dynamic>) {
        return errors.entries
            .map((e) => FieldError(
                  field: e.key,
                  message: e.value is String
                      ? e.value as String
                      : (e.value is List && (e.value as List).isNotEmpty)
                          ? (e.value as List).first.toString()
                          : e.value.toString(),
                ))
            .toList();
      }
    }
    return null;
  }

  String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Data yang dikirim tidak valid';
      case 401:
        return 'Sesi telah berakhir, silakan login kembali';
      case 403:
        return 'Anda tidak memiliki akses';
      case 404:
        return 'Data tidak ditemukan';
      case 409:
        return 'Data konflik, silakan coba lagi';
      case 422:
        return 'Data tidak dapat diproses';
      case 429:
        return 'Terlalu banyak permintaan, coba lagi nanti';
      default:
        if (statusCode >= 500) {
          return 'Terjadi kesalahan pada server';
        }
        return 'Terjadi kesalahan';
    }
  }
}
