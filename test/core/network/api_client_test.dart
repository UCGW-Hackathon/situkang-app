import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/error/failures.dart';
import 'package:situkang_app/core/network/api_response.dart';
import 'package:situkang_app/core/network/connectivity_manager.dart';
import 'package:situkang_app/core/network/dio_api_client.dart';
import 'package:situkang_app/core/storage/token_storage.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

class MockConnectivityManager extends Mock implements ConnectivityManager {}

void main() {
  late DioApiClient apiClient;
  late MockTokenStorage mockTokenStorage;
  late MockConnectivityManager mockConnectivityManager;
  late DioAdapter dioAdapter;
  late Dio dio;

  setUp(() {
    mockTokenStorage = MockTokenStorage();
    mockConnectivityManager = MockConnectivityManager();

    // Default: online and has a token
    when(() => mockConnectivityManager.isOnline).thenReturn(true);
    when(
      () => mockTokenStorage.getAccessToken(),
    ).thenAnswer((_) async => 'test-access-token');

    dio = Dio(BaseOptions(baseUrl: 'https://api.situkang.id/v1'));
    dioAdapter = DioAdapter(dio: dio);

    apiClient = DioApiClient(
      tokenStorage: mockTokenStorage,
      connectivityManager: mockConnectivityManager,
      dio: dio,
    );
  });

  group('DioApiClient', () {
    group('GET requests', () {
      test('should perform GET request and return response', () async {
        dioAdapter.onGet(
          '/test',
          (server) => server.reply(200, {'status': 'success', 'data': 'hello'}),
        );

        final response = await apiClient.get<Map<String, dynamic>>('/test');

        expect(response.statusCode, 200);
        expect(response.data?['status'], 'success');
      });

      test('should pass query parameters', () async {
        dioAdapter.onGet(
          '/test',
          (server) => server.reply(200, {'status': 'success'}),
          queryParameters: {'page': 1, 'limit': 10},
        );

        final response = await apiClient.get<Map<String, dynamic>>(
          '/test',
          queryParams: {'page': 1, 'limit': 10},
        );

        expect(response.statusCode, 200);
      });
    });

    group('POST requests', () {
      test('should perform POST request with data', () async {
        dioAdapter.onPost(
          '/test',
          (server) => server.reply(201, {'status': 'success'}),
          data: {'name': 'test'},
        );

        final response = await apiClient.post<Map<String, dynamic>>(
          '/test',
          data: {'name': 'test'},
        );

        expect(response.statusCode, 201);
      });
    });

    group('PUT requests', () {
      test('should perform PUT request with data', () async {
        dioAdapter.onPut(
          '/test',
          (server) => server.reply(200, {'status': 'success'}),
          data: {'name': 'updated'},
        );

        final response = await apiClient.put<Map<String, dynamic>>(
          '/test',
          data: {'name': 'updated'},
        );

        expect(response.statusCode, 200);
      });
    });

    group('PATCH requests', () {
      test('should perform PATCH request with data', () async {
        dioAdapter.onPatch(
          '/test',
          (server) => server.reply(200, {'status': 'success'}),
          data: {'field': 'value'},
        );

        final response = await apiClient.patch<Map<String, dynamic>>(
          '/test',
          data: {'field': 'value'},
        );

        expect(response.statusCode, 200);
      });
    });

    group('DELETE requests', () {
      test('should perform DELETE request', () async {
        dioAdapter.onDelete('/test', (server) => server.reply(204, null));

        final response = await apiClient.delete<void>('/test');

        expect(response.statusCode, 204);
      });
    });
  });

  group('AuthInterceptor', () {
    test('should attach Bearer token to request headers', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => 'my-jwt-token');

      dioAdapter.onGet(
        '/protected',
        (server) => server.reply(200, {'status': 'success'}),
      );

      await apiClient.get<Map<String, dynamic>>('/protected');

      // Verify the interceptor was called
      verify(() => mockTokenStorage.getAccessToken()).called(1);
    });

    test('should not attach header when no token available', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      dioAdapter.onGet(
        '/public',
        (server) => server.reply(200, {'status': 'success'}),
      );

      final response = await apiClient.get<Map<String, dynamic>>('/public');

      expect(response.statusCode, 200);
    });
  });

  group('ConnectivityInterceptor', () {
    test('should reject request when offline', () async {
      when(() => mockConnectivityManager.isOnline).thenReturn(false);
      when(
        () => mockConnectivityManager.checkConnectivity(),
      ).thenAnswer((_) async => ConnectivityStatus.offline);

      expect(
        () => apiClient.get<Map<String, dynamic>>('/test'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
    });

    test(
      'should recheck connectivity before rejecting stale offline status',
      () async {
        when(() => mockConnectivityManager.isOnline).thenReturn(false);
        when(
          () => mockConnectivityManager.checkConnectivity(),
        ).thenAnswer((_) async => ConnectivityStatus.online);

        dioAdapter.onGet(
          '/test',
          (server) => server.reply(200, {'status': 'success'}),
        );

        final response = await apiClient.get<Map<String, dynamic>>('/test');

        expect(response.statusCode, 200);
        verify(() => mockConnectivityManager.checkConnectivity()).called(1);
      },
    );

    test('should allow request when online', () async {
      when(() => mockConnectivityManager.isOnline).thenReturn(true);

      dioAdapter.onGet(
        '/test',
        (server) => server.reply(200, {'status': 'success'}),
      );

      final response = await apiClient.get<Map<String, dynamic>>('/test');
      expect(response.statusCode, 200);
    });
  });

  group('ErrorInterceptor', () {
    test('should map 400 to ValidationFailure', () async {
      dioAdapter.onGet(
        '/test',
        (server) => server.reply(400, {
          'status': 'error',
          'message': 'Validation failed',
          'errors': {'email': 'Email is required'},
        }),
      );

      try {
        await apiClient.get<Map<String, dynamic>>('/test');
        fail('Should have thrown');
      } on DioException catch (e) {
        expect(e.error, isA<ValidationFailure>());
        final failure = e.error as ValidationFailure;
        expect(failure.message, 'Validation failed');
        expect(failure.fieldErrors['email'], 'Email is required');
      }
    });

    test('should map 401 to AuthFailure', () async {
      dioAdapter.onGet(
        '/test',
        (server) =>
            server.reply(401, {'status': 'error', 'message': 'Token expired'}),
      );

      try {
        await apiClient.get<Map<String, dynamic>>('/test');
        fail('Should have thrown');
      } on DioException catch (e) {
        expect(e.error, isA<AuthFailure>());
        final failure = e.error as AuthFailure;
        expect(failure.message, 'Token expired');
      }
    });

    test('should map 403 to AuthFailure', () async {
      dioAdapter.onGet(
        '/test',
        (server) =>
            server.reply(403, {'status': 'error', 'message': 'Access denied'}),
      );

      try {
        await apiClient.get<Map<String, dynamic>>('/test');
        fail('Should have thrown');
      } on DioException catch (e) {
        expect(e.error, isA<AuthFailure>());
        final failure = e.error as AuthFailure;
        expect(failure.message, 'Access denied');
      }
    });

    test('should map 404 to ServerFailure', () async {
      dioAdapter.onGet(
        '/test',
        (server) =>
            server.reply(404, {'status': 'error', 'message': 'Not found'}),
      );

      try {
        await apiClient.get<Map<String, dynamic>>('/test');
        fail('Should have thrown');
      } on DioException catch (e) {
        expect(e.error, isA<ServerFailure>());
        final failure = e.error as ServerFailure;
        expect(failure.statusCode, 404);
        expect(failure.message, 'Not found');
      }
    });

    test('should map 409 to ServerFailure', () async {
      dioAdapter.onGet(
        '/test',
        (server) =>
            server.reply(409, {'status': 'error', 'message': 'Conflict'}),
      );

      try {
        await apiClient.get<Map<String, dynamic>>('/test');
        fail('Should have thrown');
      } on DioException catch (e) {
        expect(e.error, isA<ServerFailure>());
        final failure = e.error as ServerFailure;
        expect(failure.statusCode, 409);
      }
    });

    test('should map 422 to ServerFailure', () async {
      dioAdapter.onGet(
        '/test',
        (server) => server.reply(422, {
          'status': 'error',
          'message': 'Unprocessable entity',
        }),
      );

      try {
        await apiClient.get<Map<String, dynamic>>('/test');
        fail('Should have thrown');
      } on DioException catch (e) {
        expect(e.error, isA<ServerFailure>());
        final failure = e.error as ServerFailure;
        expect(failure.statusCode, 422);
      }
    });

    test('should map 429 to ServerFailure', () async {
      dioAdapter.onGet(
        '/test',
        (server) =>
            server.reply(429, {'status': 'error', 'message': 'Rate limited'}),
      );

      try {
        await apiClient.get<Map<String, dynamic>>('/test');
        fail('Should have thrown');
      } on DioException catch (e) {
        expect(e.error, isA<ServerFailure>());
        final failure = e.error as ServerFailure;
        expect(failure.statusCode, 429);
      }
    });

    test('should map 500 to ServerFailure', () async {
      dioAdapter.onGet(
        '/test',
        (server) => server.reply(500, {
          'status': 'error',
          'message': 'Internal server error',
        }),
      );

      try {
        await apiClient.get<Map<String, dynamic>>('/test');
        fail('Should have thrown');
      } on DioException catch (e) {
        expect(e.error, isA<ServerFailure>());
        final failure = e.error as ServerFailure;
        expect(failure.statusCode, 500);
      }
    });
  });

  group('ApiResponse', () {
    test('should parse success response', () {
      final json = {
        'status': 'success',
        'message': 'Data loaded',
        'data': {'id': '123', 'name': 'Test'},
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      expect(response.isSuccess, true);
      expect(response.message, 'Data loaded');
      expect(response.data?['id'], '123');
      expect(response.meta, isNull);
    });

    test('should parse paginated response', () {
      final json = {
        'status': 'success',
        'data': [
          {'id': '1'},
          {'id': '2'},
        ],
        'meta': {
          'current_page': 1,
          'per_page': 10,
          'total': 25,
          'total_pages': 3,
        },
      };

      final response = ApiResponse<List<dynamic>>.fromJson(
        json,
        fromJsonT: (data) => data as List<dynamic>,
      );

      expect(response.isSuccess, true);
      expect(response.meta, isNotNull);
      expect(response.meta!.currentPage, 1);
      expect(response.meta!.perPage, 10);
      expect(response.meta!.total, 25);
      expect(response.meta!.totalPages, 3);
      expect(response.meta!.hasNextPage, true);
    });

    test('should detect last page', () {
      const meta = PaginationMeta(
        currentPage: 3,
        perPage: 10,
        total: 25,
        totalPages: 3,
      );

      expect(meta.hasNextPage, false);
    });

    test('should parse error response', () {
      final json = {'status': 'error', 'message': 'Something went wrong'};

      final response = ApiResponse<Map<String, dynamic>?>.fromJson(json);

      expect(response.isSuccess, false);
      expect(response.message, 'Something went wrong');
      expect(response.data, isNull);
    });
  });
}
