import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that logs HTTP requests and responses in debug mode.
///
/// Only active when [kDebugMode] is true (i.e., debug builds).
/// Logs request method, URL, headers, body, response status, and errors.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '┌─── Request ───────────────────────────────────────',
        name: 'HTTP',
      );
      developer.log(
        '│ ${options.method} ${options.uri}',
        name: 'HTTP',
      );
      if (options.headers.isNotEmpty) {
        developer.log(
          '│ Headers: ${_sanitizeHeaders(options.headers)}',
          name: 'HTTP',
        );
      }
      if (options.data != null) {
        developer.log(
          '│ Body: ${_truncate(options.data.toString())}',
          name: 'HTTP',
        );
      }
      if (options.queryParameters.isNotEmpty) {
        developer.log(
          '│ Query: ${options.queryParameters}',
          name: 'HTTP',
        );
      }
      developer.log(
        '└───────────────────────────────────────────────────',
        name: 'HTTP',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      developer.log(
        '┌─── Response ──────────────────────────────────────',
        name: 'HTTP',
      );
      developer.log(
        '│ ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}',
        name: 'HTTP',
      );
      developer.log(
        '│ Body: ${_truncate(response.data.toString())}',
        name: 'HTTP',
      );
      developer.log(
        '└───────────────────────────────────────────────────',
        name: 'HTTP',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '┌─── Error ────────────────────────────────────────',
        name: 'HTTP',
      );
      developer.log(
        '│ ${err.type.name} ${err.requestOptions.method} '
        '${err.requestOptions.uri}',
        name: 'HTTP',
      );
      developer.log(
        '│ Status: ${err.response?.statusCode ?? 'N/A'}',
        name: 'HTTP',
      );
      developer.log(
        '│ Message: ${err.message ?? 'No message'}',
        name: 'HTTP',
      );
      if (err.response?.data != null) {
        developer.log(
          '│ Response: ${_truncate(err.response!.data.toString())}',
          name: 'HTTP',
        );
      }
      developer.log(
        '└───────────────────────────────────────────────────',
        name: 'HTTP',
      );
    }
    handler.next(err);
  }

  /// Sanitizes headers to avoid logging sensitive values.
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      final auth = sanitized['Authorization'] as String?;
      if (auth != null && auth.length > 15) {
        sanitized['Authorization'] = '${auth.substring(0, 15)}...';
      }
    }
    return sanitized;
  }

  /// Truncates long strings for readable log output.
  String _truncate(String text, {int maxLength = 500}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... [truncated]';
  }
}
