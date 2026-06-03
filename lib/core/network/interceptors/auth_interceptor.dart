import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

/// Interceptor that attaches the JWT Bearer token to outgoing requests.
///
/// Reads the access token from [TokenStorage] and adds it as an
/// `Authorization: Bearer <token>` header on every request.
/// If no token is available, the request proceeds without the header.
class AuthInterceptor extends Interceptor {
  /// Creates an [AuthInterceptor] with the given [tokenStorage].
  AuthInterceptor({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }
}
