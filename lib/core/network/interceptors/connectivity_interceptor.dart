import 'package:dio/dio.dart';

import '../connectivity_manager.dart';

/// Interceptor that checks network connectivity before sending requests.
///
/// If the device is offline, the request is rejected immediately with a
/// [DioException] of type [DioExceptionType.connectionError], avoiding
/// unnecessary network timeouts.
class ConnectivityInterceptor extends Interceptor {
  /// Creates a [ConnectivityInterceptor] with the given [connectivityManager].
  ConnectivityInterceptor({required ConnectivityManager connectivityManager})
      : _connectivityManager = connectivityManager;

  final ConnectivityManager _connectivityManager;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_connectivityManager.isOnline) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
          message: 'Tidak ada koneksi internet',
        ),
      );
      return;
    }
    handler.next(options);
  }
}
