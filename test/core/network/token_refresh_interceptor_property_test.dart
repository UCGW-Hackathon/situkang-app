import 'dart:async';

import 'package:dio/dio.dart';
import 'package:glados/glados.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:situkang_app/core/constants/api_endpoints.dart';
import 'package:situkang_app/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:situkang_app/core/storage/token_storage.dart';

// ─── Mocks ─────────────────────────────────────────────────────────────────────

class MockDio extends mocktail.Mock implements Dio {}

class MockErrorInterceptorHandler extends mocktail.Mock
    implements ErrorInterceptorHandler {}

class FakeRequestOptions extends mocktail.Fake implements RequestOptions {}

class FakeResponse extends mocktail.Fake implements Response<dynamic> {}

class FakeDioException extends mocktail.Fake implements DioException {}

/// In-memory token storage for tracking token state across operations.
class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  InMemoryTokenStorage({String? accessToken, String? refreshToken})
      : _accessToken = accessToken,
        _refreshToken = refreshToken;

  String? get currentAccessToken => _accessToken;
  String? get currentRefreshToken => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> hasValidTokens() async =>
      _accessToken != null && _refreshToken != null;
}

void main() {
  setUpAll(() {
    mocktail.registerFallbackValue(FakeRequestOptions());
    mocktail.registerFallbackValue(FakeResponse());
    mocktail.registerFallbackValue(FakeDioException());
  });

  // ─── Property 3: Token Refresh Interceptor ─────────────────────────────────
  // **Validates: Requirements 1.8, 1.10, 27.4**
  //
  // For any number of concurrent 401 responses, exactly one refresh attempt
  // is made. On success, all queued requests are retried with the new access
  // token. On failure, tokens are cleared.
  group('Property 3: Token Refresh Interceptor', () {
    Glados<int>(any.intInRange(1, 10)).test(
      'for any N concurrent 401 responses, exactly one refresh attempt is made and all requests are retried on success',
      (concurrentCount) async {
        final mockRefreshDio = MockDio();
        final tokenStorage = InMemoryTokenStorage(
          accessToken: 'old_access_token',
          refreshToken: 'old_refresh_token',
        );
        int refreshCallCount = 0;
        bool authLostCalled = false;

        final interceptor = TokenRefreshInterceptor(
          tokenStorage: tokenStorage,
          refreshDio: mockRefreshDio,
          onAuthenticationLost: () => authLostCalled = true,
        );

        // Use a completer to control when the refresh completes
        final refreshCompleter = Completer<Response<Map<String, dynamic>>>();

        mocktail
            .when(() => mockRefreshDio.post<Map<String, dynamic>>(
                  ApiEndpoints.authRefresh,
                  data: {'refresh_token': 'old_refresh_token'},
                ))
            .thenAnswer((_) {
          refreshCallCount++;
          return refreshCompleter.future;
        });

        mocktail
            .when(() => mockRefreshDio.fetch<dynamic>(mocktail.any()))
            .thenAnswer(
              (_) async => Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 200,
                data: {'success': true},
              ),
            );

        // Create N concurrent 401 errors
        final handlers = <MockErrorInterceptorHandler>[];
        final futures = <Future<void>>[];

        for (int i = 0; i < concurrentCount; i++) {
          final handler = MockErrorInterceptorHandler();
          handlers.add(handler);

          final requestOptions = RequestOptions(
            path: '/request_$i',
            headers: {'Authorization': 'Bearer old_access_token'},
          );
          final error = DioException(
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          );

          futures.add(interceptor.onError(error, handler));
          // Allow microtask queue to process so first request starts refresh
          await Future<void>.delayed(Duration.zero);
        }

        // Complete the refresh successfully
        refreshCompleter.complete(Response(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          statusCode: 200,
          data: {
            'data': {
              'access_token': 'new_access_token',
              'refresh_token': 'new_refresh_token',
            }
          },
        ));

        await Future.wait(futures);

        // Property: exactly one refresh attempt
        expect(refreshCallCount, equals(1),
            reason:
                'For $concurrentCount concurrent 401s, exactly 1 refresh should be attempted');

        // Property: all requests are resolved (retried successfully)
        for (int i = 0; i < concurrentCount; i++) {
          mocktail.verify(() => handlers[i].resolve(mocktail.any())).called(1);
        }

        // Property: auth lost should NOT be called on success
        expect(authLostCalled, isFalse,
            reason: 'Auth lost should not be called on successful refresh');

        // Property: new tokens are stored
        expect(tokenStorage.currentAccessToken, equals('new_access_token'));
        expect(tokenStorage.currentRefreshToken, equals('new_refresh_token'));
      },
    );

    Glados<int>(any.intInRange(1, 10)).test(
      'for any N concurrent 401 responses, on refresh failure all queued requests are rejected and tokens are cleared',
      (concurrentCount) async {
        final mockRefreshDio = MockDio();
        final tokenStorage = InMemoryTokenStorage(
          accessToken: 'old_access_token',
          refreshToken: 'old_refresh_token',
        );
        bool authLostCalled = false;

        final interceptor = TokenRefreshInterceptor(
          tokenStorage: tokenStorage,
          refreshDio: mockRefreshDio,
          onAuthenticationLost: () => authLostCalled = true,
        );

        final refreshCompleter = Completer<Response<Map<String, dynamic>>>();

        mocktail
            .when(() => mockRefreshDio.post<Map<String, dynamic>>(
                  ApiEndpoints.authRefresh,
                  data: {'refresh_token': 'old_refresh_token'},
                ))
            .thenAnswer((_) => refreshCompleter.future);

        // Create N concurrent 401 errors
        final handlers = <MockErrorInterceptorHandler>[];
        final futures = <Future<void>>[];

        for (int i = 0; i < concurrentCount; i++) {
          final handler = MockErrorInterceptorHandler();
          handlers.add(handler);

          final requestOptions = RequestOptions(
            path: '/request_$i',
            headers: {'Authorization': 'Bearer old_access_token'},
          );
          final error = DioException(
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          );

          futures.add(interceptor.onError(error, handler));
          await Future<void>.delayed(Duration.zero);
        }

        // Fail the refresh with 401 (expired refresh token)
        refreshCompleter.completeError(DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          response: Response(
            requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ));

        await Future.wait(futures);

        // Property: all requests are rejected
        for (int i = 0; i < concurrentCount; i++) {
          mocktail.verify(() => handlers[i].reject(mocktail.any())).called(1);
        }

        // Property: tokens are cleared on failure
        expect(tokenStorage.currentAccessToken, isNull,
            reason: 'Access token should be cleared on refresh failure');
        expect(tokenStorage.currentRefreshToken, isNull,
            reason: 'Refresh token should be cleared on refresh failure');

        // Property: auth lost is called
        expect(authLostCalled, isTrue,
            reason:
                'onAuthenticationLost should be called when refresh fails');
      },
    );

    Glados<int>(any.intInRange(0, 2)).test(
      'for any auth-failure status code (401, 403) from refresh endpoint, tokens are cleared',
      (statusIndex) async {
        // Map index to auth failure status codes
        final statusCode = statusIndex == 0 ? 401 : 403;

        final mockRefreshDio = MockDio();
        final tokenStorage = InMemoryTokenStorage(
          accessToken: 'access',
          refreshToken: 'refresh',
        );
        bool authLostCalled = false;

        final interceptor = TokenRefreshInterceptor(
          tokenStorage: tokenStorage,
          refreshDio: mockRefreshDio,
          onAuthenticationLost: () => authLostCalled = true,
        );

        mocktail
            .when(() => mockRefreshDio.post<Map<String, dynamic>>(
                  ApiEndpoints.authRefresh,
                  data: {'refresh_token': 'refresh'},
                ))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          response: Response(
            requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
            statusCode: statusCode,
          ),
          type: DioExceptionType.badResponse,
        ));

        final handler = MockErrorInterceptorHandler();
        final requestOptions = RequestOptions(
          path: '/test',
          headers: {'Authorization': 'Bearer access'},
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        await interceptor.onError(error, handler);

        // Property: tokens cleared on auth failure from refresh
        expect(tokenStorage.currentAccessToken, isNull);
        expect(tokenStorage.currentRefreshToken, isNull);
        expect(authLostCalled, isTrue);
        mocktail.verify(() => handler.reject(mocktail.any())).called(1);
      },
    );
  });

  // ─── Property 4: Token Rotation Integrity ──────────────────────────────────
  // **Validates: Requirements 1.10**
  //
  // After a successful refresh, the stored tokens are different from the
  // previous ones (token rotation). The old refresh token is no longer usable.
  group('Property 4: Token Rotation Integrity', () {
    final tokenChars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-';

    Glados2<String, String>(
      any.nonEmptyStringOf(tokenChars),
      any.nonEmptyStringOf(tokenChars),
    ).test(
      'after successful refresh, stored tokens differ from old tokens',
      (oldRefreshToken, newTokenSuffix) async {
        // Ensure new tokens are different from old ones
        final newAccessToken = 'new_access_$newTokenSuffix';
        final newRefreshToken = 'new_refresh_$newTokenSuffix';
        final oldAccessToken = 'old_access_token';

        final mockRefreshDio = MockDio();
        final tokenStorage = InMemoryTokenStorage(
          accessToken: oldAccessToken,
          refreshToken: oldRefreshToken,
        );

        final interceptor = TokenRefreshInterceptor(
          tokenStorage: tokenStorage,
          refreshDio: mockRefreshDio,
        );

        mocktail
            .when(() => mockRefreshDio.post<Map<String, dynamic>>(
                  ApiEndpoints.authRefresh,
                  data: {'refresh_token': oldRefreshToken},
                ))
            .thenAnswer((_) async => Response(
                  requestOptions:
                      RequestOptions(path: ApiEndpoints.authRefresh),
                  statusCode: 200,
                  data: {
                    'data': {
                      'access_token': newAccessToken,
                      'refresh_token': newRefreshToken,
                    }
                  },
                ));

        mocktail
            .when(() => mockRefreshDio.fetch<dynamic>(mocktail.any()))
            .thenAnswer(
              (_) async => Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 200,
                data: {},
              ),
            );

        final handler = MockErrorInterceptorHandler();
        final requestOptions = RequestOptions(
          path: '/test',
          headers: {'Authorization': 'Bearer $oldAccessToken'},
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        await interceptor.onError(error, handler);

        // Property: new access token differs from old
        expect(tokenStorage.currentAccessToken, equals(newAccessToken));
        expect(tokenStorage.currentAccessToken, isNot(equals(oldAccessToken)),
            reason: 'New access token must differ from old access token');

        // Property: new refresh token differs from old
        expect(tokenStorage.currentRefreshToken, equals(newRefreshToken));
        expect(
            tokenStorage.currentRefreshToken, isNot(equals(oldRefreshToken)),
            reason: 'New refresh token must differ from old refresh token');
      },
    );

    Glados<String>(
            any.nonEmptyStringOf('abcdefghijklmnopqrstuvwxyz0123456789'))
        .test(
      'old refresh token is no longer usable after successful rotation (second refresh uses new token)',
      (oldRefreshToken) async {
        final mockRefreshDio = MockDio();
        final tokenStorage = InMemoryTokenStorage(
          accessToken: 'old_access',
          refreshToken: oldRefreshToken,
        );

        final interceptor = TokenRefreshInterceptor(
          tokenStorage: tokenStorage,
          refreshDio: mockRefreshDio,
        );

        final newRefreshToken = 'rotated_${oldRefreshToken}_new';

        // First refresh: old token → new tokens
        mocktail
            .when(() => mockRefreshDio.post<Map<String, dynamic>>(
                  ApiEndpoints.authRefresh,
                  data: {'refresh_token': oldRefreshToken},
                ))
            .thenAnswer((_) async => Response(
                  requestOptions:
                      RequestOptions(path: ApiEndpoints.authRefresh),
                  statusCode: 200,
                  data: {
                    'data': {
                      'access_token': 'new_access_1',
                      'refresh_token': newRefreshToken,
                    }
                  },
                ));

        // Second refresh: new token → newer tokens
        mocktail
            .when(() => mockRefreshDio.post<Map<String, dynamic>>(
                  ApiEndpoints.authRefresh,
                  data: {'refresh_token': newRefreshToken},
                ))
            .thenAnswer((_) async => Response(
                  requestOptions:
                      RequestOptions(path: ApiEndpoints.authRefresh),
                  statusCode: 200,
                  data: {
                    'data': {
                      'access_token': 'new_access_2',
                      'refresh_token': 'final_refresh',
                    }
                  },
                ));

        mocktail
            .when(() => mockRefreshDio.fetch<dynamic>(mocktail.any()))
            .thenAnswer(
              (_) async => Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 200,
                data: {},
              ),
            );

        // First 401 → triggers refresh with old token
        final handler1 = MockErrorInterceptorHandler();
        final error1 = DioException(
          requestOptions: RequestOptions(
            path: '/test1',
            headers: {'Authorization': 'Bearer old_access'},
          ),
          response: Response(
            requestOptions: RequestOptions(path: '/test1'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        await interceptor.onError(error1, handler1);

        // After first refresh, storage should have new tokens
        expect(tokenStorage.currentRefreshToken, equals(newRefreshToken),
            reason: 'After first refresh, new refresh token should be stored');
        expect(tokenStorage.currentRefreshToken, isNot(equals(oldRefreshToken)),
            reason: 'Old refresh token should no longer be in storage');

        // Second 401 → triggers refresh with NEW token (not old)
        final handler2 = MockErrorInterceptorHandler();
        final error2 = DioException(
          requestOptions: RequestOptions(
            path: '/test2',
            headers: {'Authorization': 'Bearer new_access_1'},
          ),
          response: Response(
            requestOptions: RequestOptions(path: '/test2'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        await interceptor.onError(error2, handler2);

        // Property: second refresh used the NEW refresh token, not the old one
        mocktail.verify(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': newRefreshToken},
            )).called(1);

        // Property: old refresh token was only used once (in the first refresh)
        mocktail.verify(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': oldRefreshToken},
            )).called(1);

        // Final state: newest tokens stored
        expect(tokenStorage.currentAccessToken, equals('new_access_2'));
        expect(tokenStorage.currentRefreshToken, equals('final_refresh'));
      },
    );
  });
}
