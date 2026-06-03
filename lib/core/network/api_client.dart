import 'package:dio/dio.dart';

/// Abstract interface for the HTTP API client.
///
/// Provides typed methods for all HTTP verbs used by the application.
/// Implementations should configure base URL, timeouts, and interceptors.
abstract class ApiClient {
  /// Performs a GET request to the given [path] with optional [queryParams].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
  });

  /// Performs a POST request to the given [path] with optional [data] body.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
  });

  /// Performs a PUT request to the given [path] with optional [data] body.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  });

  /// Performs a PATCH request to the given [path] with optional [data] body.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
  });

  /// Performs a DELETE request to the given [path].
  Future<Response<T>> delete<T>(String path);

  /// Performs a multipart file upload to the given [path] with [data].
  Future<Response<T>> upload<T>(
    String path, {
    required FormData data,
  });
}
