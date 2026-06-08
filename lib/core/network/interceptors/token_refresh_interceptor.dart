import 'dart:async';

import 'package:dio/dio.dart';

import '../../constants/api_endpoints.dart';
import '../../storage/token_storage.dart';

/// Callback type for notifying the app that authentication has been lost.
///
/// Called when a token refresh fails (401/403 from the refresh endpoint),
/// indicating the user should be redirected to the login screen.
typedef OnAuthenticationLost = void Function();

/// Interceptor that handles automatic token refresh on 401 responses.
///
/// When a request receives a 401 Unauthorized response, this interceptor:
/// 1. Queues any concurrent requests that also receive 401
/// 2. Attempts exactly one token refresh using the stored refresh token
/// 3. On success: saves new tokens and retries all queued requests
/// 4. On failure (401/403): clears tokens and notifies auth state change
/// 5. On network error: retains tokens (allows retry on next call)
///
/// Uses a separate [Dio] instance for the refresh call to avoid
/// interceptor loops (the refresh request should not trigger this
/// interceptor again).
///
/// Requirements: 1.8, 1.9, 1.10, 27.2, 27.3, 27.4, 27.5
class TokenRefreshInterceptor extends Interceptor {
  /// Creates a [TokenRefreshInterceptor].
  ///
  /// - [tokenStorage]: Used to get the refresh token and save new tokens.
  /// - [refreshDio]: A separate Dio instance for making the refresh API call.
  ///   This instance should NOT have this interceptor attached to avoid loops.
  /// - [onAuthenticationLost]: Callback invoked when refresh fails and the
  ///   user should be redirected to login.
  TokenRefreshInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshDio,
    OnAuthenticationLost? onAuthenticationLost,
  })  : _tokenStorage = tokenStorage,
        _refreshDio = refreshDio,
        _onAuthenticationLost = onAuthenticationLost;

  final TokenStorage _tokenStorage;
  final Dio _refreshDio;
  final OnAuthenticationLost? _onAuthenticationLost;

  /// Whether a token refresh is currently in progress.
  bool _isRefreshing = false;

  /// Queue of pending requests waiting for the token refresh to complete.
  /// Each entry is a completer that resolves with the new access token
  /// on success, or completes with an error on failure.
  final List<Completer<String>> _pendingRequests = [];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 responses
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't intercept 401 from the refresh endpoint itself
    if (_isRefreshRequest(err.requestOptions)) {
      return handler.next(err);
    }

    // If a refresh is already in progress, queue this request
    if (_isRefreshing) {
      try {
        final newToken = await _waitForRefresh();
        final response = await _retryRequest(err.requestOptions, newToken);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.reject(e);
      } catch (e) {
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: e,
          ),
        );
      }
    }

    // Start the refresh process
    _isRefreshing = true;

    try {
      final newAccessToken = await _performTokenRefresh();

      // Refresh succeeded — retry the original request
      final response =
          await _retryRequest(err.requestOptions, newAccessToken);

      // Resolve all queued requests with the new token
      _resolveAllPending(newAccessToken);

      return handler.resolve(response);
    } on DioException catch (refreshError) {
      final statusCode = refreshError.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        // Refresh token is expired or revoked — clear tokens and notify
        await _tokenStorage.clearTokens();
        _onAuthenticationLost?.call();
        _rejectAllPending(refreshError);
      } else if (_isNetworkError(refreshError)) {
        // Network error during refresh — retain tokens for future retry
        _rejectAllPending(refreshError);
      } else {
        // Other server errors — clear tokens as a safety measure
        await _tokenStorage.clearTokens();
        _onAuthenticationLost?.call();
        _rejectAllPending(refreshError);
      }

      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: refreshError.response,
          type: refreshError.type,
          error: refreshError.error,
          message: refreshError.message,
        ),
      );
    } catch (e) {
      // Unexpected error — reject everything
      final dioError = DioException(
        requestOptions: err.requestOptions,
        error: e,
      );
      _rejectAllPending(dioError);
      return handler.reject(dioError);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Performs the actual token refresh API call.
  ///
  /// Returns the new access token on success.
  /// Throws [DioException] on failure.
  Future<String> _performTokenRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
        error: 'No refresh token available',
      );
    }

    final response = await _refreshDio.post<Map<String, dynamic>>(
      ApiEndpoints.authRefresh,
      data: {'refresh_token': refreshToken},
    );

    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
        error: 'Empty response from refresh endpoint',
      );
    }

    // Extract tokens from response — handle nested 'data' field
    final tokenData = data['data'] as Map<String, dynamic>? ?? data;
    final newAccessToken = tokenData['access_token'] as String?;
    final newRefreshToken = tokenData['refresh_token'] as String?;

    if (newAccessToken == null || newRefreshToken == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
        error: 'Invalid token response format',
      );
    }

    // Save new tokens (token rotation: old refresh token is now invalid)
    await _tokenStorage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );

    return newAccessToken;
  }

  /// Retries the original request with the new access token.
  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) {
    requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
    return _refreshDio.fetch(requestOptions);
  }

  /// Waits for an in-progress refresh to complete.
  ///
  /// Returns the new access token when the refresh succeeds.
  /// Throws if the refresh fails.
  Future<String> _waitForRefresh() {
    final completer = Completer<String>();
    _pendingRequests.add(completer);
    return completer.future;
  }

  /// Resolves all pending request completers with the new access token.
  void _resolveAllPending(String newAccessToken) {
    for (final completer in _pendingRequests) {
      if (!completer.isCompleted) {
        completer.complete(newAccessToken);
      }
    }
    _pendingRequests.clear();
  }

  /// Rejects all pending request completers with the given error.
  void _rejectAllPending(Object error) {
    for (final completer in _pendingRequests) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pendingRequests.clear();
  }

  /// Checks if the request is a refresh token request (to avoid loops).
  bool _isRefreshRequest(RequestOptions options) {
    return options.path == ApiEndpoints.authRefresh ||
        options.path.endsWith(ApiEndpoints.authRefresh);
  }

  /// Checks if the error is a network-related error.
  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }
}
