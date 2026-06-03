import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/constants/api_endpoints.dart';
import 'package:situkang_app/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:situkang_app/core/storage/token_storage.dart';

// ─── Mocks ─────────────────────────────────────────────────────────────────────

class MockTokenStorage extends Mock implements TokenStorage {}

class MockDio extends Mock implements Dio {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeResponse extends Fake implements Response<dynamic> {}

class FakeDioException extends Fake implements DioException {}

void main() {
  late MockTokenStorage mockTokenStorage;
  late MockDio mockRefreshDio;
  late TokenRefreshInterceptor interceptor;
  late bool authLostCalled;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse());
    registerFallbackValue(FakeDioException());
  });

  setUp(() {
    mockTokenStorage = MockTokenStorage();
    mockRefreshDio = MockDio();
    authLostCalled = false;

    interceptor = TokenRefreshInterceptor(
      tokenStorage: mockTokenStorage,
      refreshDio: mockRefreshDio,
      onAuthenticationLost: () => authLostCalled = true,
    );
  });

  RequestOptions createRequestOptions({String path = '/test'}) {
    return RequestOptions(
      path: path,
      baseUrl: 'https://api.situkang.id/v1',
      headers: {'Authorization': 'Bearer old_token'},
    );
  }

  DioException create401Error({String path = '/test'}) {
    final requestOptions = createRequestOptions(path: path);
    return DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 401,
        data: {'message': 'Unauthorized'},
      ),
      type: DioExceptionType.badResponse,
    );
  }

  group('TokenRefreshInterceptor', () {
    group('non-401 errors', () {
      test('passes through non-401 errors without intercepting', () {
        final handler = MockErrorInterceptorHandler();
        final requestOptions = createRequestOptions();
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, handler);

        verify(() => handler.next(error)).called(1);
        verifyNever(() => handler.resolve(any()));
        verifyNever(() => handler.reject(any()));
      });

      test('passes through 403 errors without intercepting', () {
        final handler = MockErrorInterceptorHandler();
        final requestOptions = createRequestOptions();
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, handler);

        verify(() => handler.next(error)).called(1);
      });
    });

    group('successful token refresh', () {
      test('refreshes token and retries request on 401', () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'valid_refresh_token');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'valid_refresh_token'},
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
              statusCode: 200,
              data: {
                'data': {
                  'access_token': 'new_access_token',
                  'refresh_token': 'new_refresh_token',
                }
              },
            ));

        when(() => mockTokenStorage.saveTokens(
              accessToken: 'new_access_token',
              refreshToken: 'new_refresh_token',
            )).thenAnswer((_) async {});

        when(() => mockRefreshDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: createRequestOptions(),
            statusCode: 200,
            data: {'result': 'success'},
          ),
        );

        await interceptor.onError(error, handler);

        verify(() => mockTokenStorage.getRefreshToken()).called(1);
        verify(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'valid_refresh_token'},
            )).called(1);
        verify(() => mockTokenStorage.saveTokens(
              accessToken: 'new_access_token',
              refreshToken: 'new_refresh_token',
            )).called(1);
        verify(() => handler.resolve(any())).called(1);
        expect(authLostCalled, isFalse);
      });

      test('saves both new access and refresh tokens (token rotation)',
          () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'old_refresh');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'old_refresh'},
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
              statusCode: 200,
              data: {
                'data': {
                  'access_token': 'rotated_access',
                  'refresh_token': 'rotated_refresh',
                }
              },
            ));

        when(() => mockTokenStorage.saveTokens(
              accessToken: 'rotated_access',
              refreshToken: 'rotated_refresh',
            )).thenAnswer((_) async {});

        when(() => mockRefreshDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: createRequestOptions(),
            statusCode: 200,
            data: {},
          ),
        );

        await interceptor.onError(error, handler);

        verify(() => mockTokenStorage.saveTokens(
              accessToken: 'rotated_access',
              refreshToken: 'rotated_refresh',
            )).called(1);
      });

      test('retries original request with new access token', () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh_token');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'refresh_token'},
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
              statusCode: 200,
              data: {
                'data': {
                  'access_token': 'new_token',
                  'refresh_token': 'new_refresh',
                }
              },
            ));

        when(() => mockTokenStorage.saveTokens(
              accessToken: 'new_token',
              refreshToken: 'new_refresh',
            )).thenAnswer((_) async {});

        when(() => mockRefreshDio.fetch<dynamic>(any())).thenAnswer(
          (invocation) async {
            final options =
                invocation.positionalArguments[0] as RequestOptions;
            expect(options.headers['Authorization'], 'Bearer new_token');
            return Response(
              requestOptions: options,
              statusCode: 200,
              data: {'retried': true},
            );
          },
        );

        await interceptor.onError(error, handler);

        verify(() => mockRefreshDio.fetch<dynamic>(any())).called(1);
      });
    });

    group('refresh failure - expired/revoked refresh token', () {
      test('clears tokens on 401 from refresh endpoint', () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'expired_refresh');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'expired_refresh'},
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          response: Response(
            requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ));

        when(() => mockTokenStorage.clearTokens())
            .thenAnswer((_) async {});

        await interceptor.onError(error, handler);

        verify(() => mockTokenStorage.clearTokens()).called(1);
        expect(authLostCalled, isTrue);
        verify(() => handler.reject(any())).called(1);
      });

      test('clears tokens on 403 from refresh endpoint', () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'revoked_refresh');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'revoked_refresh'},
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          response: Response(
            requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ));

        when(() => mockTokenStorage.clearTokens())
            .thenAnswer((_) async {});

        await interceptor.onError(error, handler);

        verify(() => mockTokenStorage.clearTokens()).called(1);
        expect(authLostCalled, isTrue);
        verify(() => handler.reject(any())).called(1);
      });

      test('notifies onAuthenticationLost callback on refresh failure',
          () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'bad_refresh');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'bad_refresh'},
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          response: Response(
            requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ));

        when(() => mockTokenStorage.clearTokens())
            .thenAnswer((_) async {});

        await interceptor.onError(error, handler);

        expect(authLostCalled, isTrue);
      });
    });

    group('network error during refresh', () {
      test('retains tokens on network error during refresh', () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'valid_refresh');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'valid_refresh'},
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        ));

        await interceptor.onError(error, handler);

        // Should NOT clear tokens on network error
        verifyNever(() => mockTokenStorage.clearTokens());
        // Should NOT notify auth lost
        expect(authLostCalled, isFalse);
        // Should reject the current request
        verify(() => handler.reject(any())).called(1);
      });

      test('retains tokens on timeout during refresh', () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'valid_refresh');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'valid_refresh'},
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          type: DioExceptionType.connectionTimeout,
        ));

        await interceptor.onError(error, handler);

        verifyNever(() => mockTokenStorage.clearTokens());
        expect(authLostCalled, isFalse);
        verify(() => handler.reject(any())).called(1);
      });
    });

    group('no refresh token available', () {
      test('rejects request when no refresh token is stored', () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => null);
        when(() => mockTokenStorage.clearTokens())
            .thenAnswer((_) async {});

        await interceptor.onError(error, handler);

        verify(() => handler.reject(any())).called(1);
        verifyNever(() => mockRefreshDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
            ));
      });

      test('rejects request when refresh token is empty', () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => '');
        when(() => mockTokenStorage.clearTokens())
            .thenAnswer((_) async {});

        await interceptor.onError(error, handler);

        verify(() => handler.reject(any())).called(1);
      });
    });

    group('concurrent request queuing', () {
      test('queues concurrent 401 requests during refresh', () async {
        final handler1 = MockErrorInterceptorHandler();
        final handler2 = MockErrorInterceptorHandler();
        final handler3 = MockErrorInterceptorHandler();

        final error1 = create401Error(path: '/request1');
        final error2 = create401Error(path: '/request2');
        final error3 = create401Error(path: '/request3');

        // Use a completer to control when the refresh completes
        final refreshCompleter = Completer<Response<Map<String, dynamic>>>();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh_token');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'refresh_token'},
            )).thenAnswer((_) => refreshCompleter.future);

        when(() => mockTokenStorage.saveTokens(
              accessToken: 'new_access',
              refreshToken: 'new_refresh',
            )).thenAnswer((_) async {});

        when(() => mockRefreshDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: createRequestOptions(),
            statusCode: 200,
            data: {'success': true},
          ),
        );

        // Fire all three requests concurrently
        final future1 = interceptor.onError(error1, handler1);
        // Small delay to ensure first request starts refresh
        await Future<void>.delayed(Duration.zero);
        final future2 = interceptor.onError(error2, handler2);
        final future3 = interceptor.onError(error3, handler3);

        // Complete the refresh
        refreshCompleter.complete(Response(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          statusCode: 200,
          data: {
            'data': {
              'access_token': 'new_access',
              'refresh_token': 'new_refresh',
            }
          },
        ));

        await Future.wait([future1, future2, future3]);

        // Only one refresh call should have been made
        verify(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'refresh_token'},
            )).called(1);

        // All three requests should be resolved
        verify(() => handler1.resolve(any())).called(1);
        verify(() => handler2.resolve(any())).called(1);
        verify(() => handler3.resolve(any())).called(1);
      });

      test('rejects all queued requests when refresh fails', () async {
        final handler1 = MockErrorInterceptorHandler();
        final handler2 = MockErrorInterceptorHandler();

        final error1 = create401Error(path: '/request1');
        final error2 = create401Error(path: '/request2');

        final refreshCompleter = Completer<Response<Map<String, dynamic>>>();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh_token');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'refresh_token'},
            )).thenAnswer((_) => refreshCompleter.future);

        when(() => mockTokenStorage.clearTokens())
            .thenAnswer((_) async {});

        // Fire both requests
        final future1 = interceptor.onError(error1, handler1);
        await Future<void>.delayed(Duration.zero);
        final future2 = interceptor.onError(error2, handler2);

        // Fail the refresh with 401
        refreshCompleter.completeError(DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
          response: Response(
            requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ));

        await Future.wait([future1, future2]);

        // Both should be rejected
        verify(() => handler1.reject(any())).called(1);
        verify(() => handler2.reject(any())).called(1);
        verify(() => mockTokenStorage.clearTokens()).called(1);
        expect(authLostCalled, isTrue);
      });
    });

    group('refresh endpoint bypass', () {
      test('does not intercept 401 from the refresh endpoint itself', () {
        final handler = MockErrorInterceptorHandler();
        final requestOptions =
            createRequestOptions(path: ApiEndpoints.authRefresh);
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, handler);

        verify(() => handler.next(error)).called(1);
        verifyNever(() => mockTokenStorage.getRefreshToken());
      });
    });

    group('response format handling', () {
      test('handles flat token response (no nested data field)', () async {
        final handler = MockErrorInterceptorHandler();
        final error = create401Error();

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh_token');

        when(() => mockRefreshDio.post<Map<String, dynamic>>(
              ApiEndpoints.authRefresh,
              data: {'refresh_token': 'refresh_token'},
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ApiEndpoints.authRefresh),
              statusCode: 200,
              data: {
                'access_token': 'flat_access',
                'refresh_token': 'flat_refresh',
              },
            ));

        when(() => mockTokenStorage.saveTokens(
              accessToken: 'flat_access',
              refreshToken: 'flat_refresh',
            )).thenAnswer((_) async {});

        when(() => mockRefreshDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: createRequestOptions(),
            statusCode: 200,
            data: {},
          ),
        );

        await interceptor.onError(error, handler);

        verify(() => mockTokenStorage.saveTokens(
              accessToken: 'flat_access',
              refreshToken: 'flat_refresh',
            )).called(1);
        verify(() => handler.resolve(any())).called(1);
      });
    });
  });
}
