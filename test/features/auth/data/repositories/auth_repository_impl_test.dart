import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/constants/enums.dart';
import 'package:situkang_app/core/error/failures.dart';
import 'package:situkang_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:situkang_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:situkang_app/features/auth/data/models/token_model.dart';
import 'package:situkang_app/features/auth/data/models/user_model.dart';
import 'package:situkang_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:situkang_app/features/auth/domain/repositories/auth_repository.dart';

// Mocks
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  // Test data
  final tUserModel = UserModel(
    userId: 'user-123',
    fullName: 'John Doe',
    email: 'john@example.com',
    phone: '+6281234567890',
    role: UserRole.user,
    createdAt: DateTime(2024, 1, 1),
  );

  const tTokenModel = TokenModel(
    accessToken: 'access-token-123',
    refreshToken: 'refresh-token-123',
    expiresIn: 3600,
  );

  const tNewTokenModel = TokenModel(
    accessToken: 'new-access-token-456',
    refreshToken: 'new-refresh-token-456',
    expiresIn: 3600,
  );

  const tRegisterParams = RegisterParams(
    fullName: 'John Doe',
    email: 'john@example.com',
    phone: '+6281234567890',
    password: 'Password1',
    passwordConfirmation: 'Password1',
    role: UserRole.user,
  );

  setUpAll(() {
    registerFallbackValue(tRegisterParams);
  });

  group('login', () {
    test('should return (User, Token) and save tokens on success', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => (tUserModel, tTokenModel));
      when(() => mockLocalDataSource.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      // Act
      final result = await repository.login(
        email: 'john@example.com',
        password: 'Password1',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (data) {
          final (user, token) = data;
          expect(user.id, 'user-123');
          expect(user.fullName, 'John Doe');
          expect(token.accessToken, 'access-token-123');
          expect(token.refreshToken, 'refresh-token-123');
        },
      );
      verify(() => mockLocalDataSource.saveTokens(
            accessToken: 'access-token-123',
            refreshToken: 'refresh-token-123',
          )).called(1);
    });

    test('should return AuthFailure when credentials are invalid (401)',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'message': 'Email atau password salah'},
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.login(
        email: 'john@example.com',
        password: 'wrong-password',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Email atau password salah');
        },
        (_) => fail('Should be Left'),
      );
      verifyNever(() => mockLocalDataSource.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionError,
      ));

      // Act
      final result = await repository.login(
        email: 'john@example.com',
        password: 'Password1',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should return TimeoutFailure on connection timeout', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionTimeout,
      ));

      // Act
      final result = await repository.login(
        email: 'john@example.com',
        password: 'Password1',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<TimeoutFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('register', () {
    test('should return (User, Token) and save tokens on success', () async {
      // Arrange
      when(() => mockRemoteDataSource.register(any()))
          .thenAnswer((_) async => (tUserModel, tTokenModel));
      when(() => mockLocalDataSource.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      // Act
      final result = await repository.register(params: tRegisterParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (data) {
          final (user, token) = data;
          expect(user.id, 'user-123');
          expect(user.email, 'john@example.com');
          expect(token.accessToken, 'access-token-123');
        },
      );
      verify(() => mockLocalDataSource.saveTokens(
            accessToken: 'access-token-123',
            refreshToken: 'refresh-token-123',
          )).called(1);
    });

    test(
        'should return ServerFailure with field errors when email is duplicate (409)',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.register(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 409,
          data: {
            'message': 'Email sudah terdaftar',
            'errors': {
              'email': ['The email has already been taken.']
            },
          },
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.register(params: tRegisterParams);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          final serverFailure = failure as ServerFailure;
          expect(serverFailure.statusCode, 409);
          expect(serverFailure.fieldErrors, isNotNull);
          expect(serverFailure.fieldErrors!.length, 1);
          expect(serverFailure.fieldErrors!.first.field, 'email');
        },
        (_) => fail('Should be Left'),
      );
    });

    test(
        'should return ServerFailure with field errors when phone is duplicate (409)',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.register(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 409,
          data: {
            'message': 'Nomor telepon sudah terdaftar',
            'errors': {
              'phone': ['The phone has already been taken.']
            },
          },
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.register(params: tRegisterParams);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          final serverFailure = failure as ServerFailure;
          expect(serverFailure.statusCode, 409);
          expect(serverFailure.fieldErrors, isNotNull);
          expect(serverFailure.fieldErrors!.first.field, 'phone');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRemoteDataSource.register(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        type: DioExceptionType.connectionError,
      ));

      // Act
      final result = await repository.register(params: tRegisterParams);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should return TimeoutFailure on send timeout', () async {
      // Arrange
      when(() => mockRemoteDataSource.register(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        type: DioExceptionType.sendTimeout,
      ));

      // Act
      final result = await repository.register(params: tRegisterParams);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<TimeoutFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('logout', () {
    test('should clear tokens and return success when API call succeeds',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.logout()).thenAnswer((_) async {});
      when(() => mockLocalDataSource.clearTokens()).thenAnswer((_) async {});

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.logout()).called(1);
      verify(() => mockLocalDataSource.clearTokens()).called(1);
    });

    test('should clear tokens even when API call fails with network error',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.logout()).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/logout'),
        type: DioExceptionType.connectionError,
      ));
      when(() => mockLocalDataSource.clearTokens()).thenAnswer((_) async {});

      // Act
      final result = await repository.logout();

      // Assert
      // Should still return success since local tokens are cleared
      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.clearTokens()).called(1);
    });

    test('should clear tokens even when API call fails with timeout',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.logout()).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/logout'),
        type: DioExceptionType.connectionTimeout,
      ));
      when(() => mockLocalDataSource.clearTokens()).thenAnswer((_) async {});

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.clearTokens()).called(1);
    });

    test('should clear tokens even on unexpected exceptions', () async {
      // Arrange
      when(() => mockRemoteDataSource.logout())
          .thenThrow(Exception('Unexpected error'));
      when(() => mockLocalDataSource.clearTokens()).thenAnswer((_) async {});

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.clearTokens()).called(1);
    });
  });

  group('refreshToken', () {
    test('should save new tokens and return Token on success (rotation)',
        () async {
      // Arrange
      when(() => mockLocalDataSource.getRefreshToken())
          .thenAnswer((_) async => 'old-refresh-token');
      when(() => mockRemoteDataSource.refresh(
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async => tNewTokenModel);
      when(() => mockLocalDataSource.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      // Act
      final result = await repository.refreshToken();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (token) {
          expect(token.accessToken, 'new-access-token-456');
          expect(token.refreshToken, 'new-refresh-token-456');
        },
      );
      verify(() => mockRemoteDataSource.refresh(
            refreshToken: 'old-refresh-token',
          )).called(1);
      verify(() => mockLocalDataSource.saveTokens(
            accessToken: 'new-access-token-456',
            refreshToken: 'new-refresh-token-456',
          )).called(1);
    });

    test('should return AuthFailure when no refresh token is stored',
        () async {
      // Arrange
      when(() => mockLocalDataSource.getRefreshToken())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.refreshToken();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(
              (failure as AuthFailure).errorCode, 'NO_REFRESH_TOKEN');
        },
        (_) => fail('Should be Left'),
      );
    });

    test(
        'should clear tokens and return AuthFailure when refresh fails with 401',
        () async {
      // Arrange
      when(() => mockLocalDataSource.getRefreshToken())
          .thenAnswer((_) async => 'expired-refresh-token');
      when(() => mockRemoteDataSource.refresh(
            refreshToken: any(named: 'refreshToken'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: 401,
          data: {'message': 'Refresh token expired'},
        ),
        type: DioExceptionType.badResponse,
      ));
      when(() => mockLocalDataSource.clearTokens()).thenAnswer((_) async {});

      // Act
      final result = await repository.refreshToken();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect((failure as AuthFailure).errorCode,
              'REFRESH_TOKEN_EXPIRED');
        },
        (_) => fail('Should be Left'),
      );
      verify(() => mockLocalDataSource.clearTokens()).called(1);
    });

    test('should return NetworkFailure on connection error without clearing tokens',
        () async {
      // Arrange
      when(() => mockLocalDataSource.getRefreshToken())
          .thenAnswer((_) async => 'valid-refresh-token');
      when(() => mockRemoteDataSource.refresh(
            refreshToken: any(named: 'refreshToken'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        type: DioExceptionType.connectionError,
      ));

      // Act
      final result = await repository.refreshToken();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
      // Should NOT clear tokens on network error (token may still be valid)
      verifyNever(() => mockLocalDataSource.clearTokens());
    });

    test('should return TimeoutFailure on timeout without clearing tokens',
        () async {
      // Arrange
      when(() => mockLocalDataSource.getRefreshToken())
          .thenAnswer((_) async => 'valid-refresh-token');
      when(() => mockRemoteDataSource.refresh(
            refreshToken: any(named: 'refreshToken'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        type: DioExceptionType.receiveTimeout,
      ));

      // Act
      final result = await repository.refreshToken();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<TimeoutFailure>()),
        (_) => fail('Should be Left'),
      );
      verifyNever(() => mockLocalDataSource.clearTokens());
    });
  });
}
