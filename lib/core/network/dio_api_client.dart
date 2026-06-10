import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'connectivity_manager.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/token_refresh_interceptor.dart';

/// Dio-based implementation of [ApiClient].
///
/// Configures Dio with the app's base URL, timeouts, and interceptor chain:
/// 1. [ConnectivityInterceptor] — Rejects requests when offline
/// 2. [AuthInterceptor] — Attaches JWT Bearer token
/// 3. [LoggingInterceptor] — Logs requests/responses in debug mode
/// 4. [ErrorInterceptor] — Maps HTTP errors to typed Failure objects
///
/// The interceptor order matters: connectivity check first, then auth,
/// then logging (to see the final request), and error mapping last
/// (to catch all errors from previous interceptors).
@LazySingleton(as: ApiClient)
class DioApiClient implements ApiClient {
  /// Creates a [DioApiClient] with the required dependencies.
  ///
  /// Optionally accepts a pre-configured [Dio] instance for testing.
  DioApiClient({
    required TokenStorage tokenStorage,
    required ConnectivityManager connectivityManager,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      sendTimeout: AppConstants.sendTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.addAll([
      ConnectivityInterceptor(connectivityManager: connectivityManager),
      AuthInterceptor(tokenStorage: tokenStorage),
      TokenRefreshInterceptor(
        tokenStorage: tokenStorage,
        refreshDio: Dio(_dio.options),
      ),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  final Dio _dio;

  /// Exposes the underlying [Dio] instance for adding additional interceptors
  /// (e.g., TokenRefreshInterceptor) after construction.
  Dio get dio => _dio;

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get<T>(path, queryParameters: queryParams);
  }

  @override
  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  @override
  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  @override
  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(path, data: data);
  }

  @override
  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }

  @override
  Future<Response<T>> upload<T>(String path, {required FormData data}) {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }
}
