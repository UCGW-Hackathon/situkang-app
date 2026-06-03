import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/storage/secure_token_storage_impl.dart';
import 'package:situkang_app/core/storage/token_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStorage = SecureTokenStorageImpl(storage: mockStorage);
  });

  group('SecureTokenStorageImpl', () {
    group('saveTokens', () {
      test('should write both access and refresh tokens to secure storage',
          () async {
        // Arrange
        when(
          () => mockStorage.write(
            key: TokenStorageKeys.accessToken,
            value: 'test_access_token',
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.write(
            key: TokenStorageKeys.refreshToken,
            value: 'test_refresh_token',
          ),
        ).thenAnswer((_) async {});

        // Act
        await tokenStorage.saveTokens(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
        );

        // Assert
        verify(
          () => mockStorage.write(
            key: TokenStorageKeys.accessToken,
            value: 'test_access_token',
          ),
        ).called(1);
        verify(
          () => mockStorage.write(
            key: TokenStorageKeys.refreshToken,
            value: 'test_refresh_token',
          ),
        ).called(1);
      });
    });

    group('getAccessToken', () {
      test('should return stored access token', () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.accessToken),
        ).thenAnswer((_) async => 'stored_access_token');

        // Act
        final result = await tokenStorage.getAccessToken();

        // Assert
        expect(result, 'stored_access_token');
      });

      test('should return null when no access token is stored', () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.accessToken),
        ).thenAnswer((_) async => null);

        // Act
        final result = await tokenStorage.getAccessToken();

        // Assert
        expect(result, isNull);
      });
    });

    group('getRefreshToken', () {
      test('should return stored refresh token', () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.refreshToken),
        ).thenAnswer((_) async => 'stored_refresh_token');

        // Act
        final result = await tokenStorage.getRefreshToken();

        // Assert
        expect(result, 'stored_refresh_token');
      });

      test('should return null when no refresh token is stored', () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.refreshToken),
        ).thenAnswer((_) async => null);

        // Act
        final result = await tokenStorage.getRefreshToken();

        // Assert
        expect(result, isNull);
      });
    });

    group('clearTokens', () {
      test('should delete both tokens from secure storage', () async {
        // Arrange
        when(
          () => mockStorage.delete(key: TokenStorageKeys.accessToken),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.delete(key: TokenStorageKeys.refreshToken),
        ).thenAnswer((_) async {});

        // Act
        await tokenStorage.clearTokens();

        // Assert
        verify(
          () => mockStorage.delete(key: TokenStorageKeys.accessToken),
        ).called(1);
        verify(
          () => mockStorage.delete(key: TokenStorageKeys.refreshToken),
        ).called(1);
      });
    });

    group('hasValidTokens', () {
      test('should return true when both tokens are present and non-empty',
          () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.accessToken),
        ).thenAnswer((_) async => 'valid_access_token');
        when(
          () => mockStorage.read(key: TokenStorageKeys.refreshToken),
        ).thenAnswer((_) async => 'valid_refresh_token');

        // Act
        final result = await tokenStorage.hasValidTokens();

        // Assert
        expect(result, isTrue);
      });

      test('should return false when access token is null', () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.accessToken),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorage.read(key: TokenStorageKeys.refreshToken),
        ).thenAnswer((_) async => 'valid_refresh_token');

        // Act
        final result = await tokenStorage.hasValidTokens();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when refresh token is null', () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.accessToken),
        ).thenAnswer((_) async => 'valid_access_token');
        when(
          () => mockStorage.read(key: TokenStorageKeys.refreshToken),
        ).thenAnswer((_) async => null);

        // Act
        final result = await tokenStorage.hasValidTokens();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when access token is empty', () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.accessToken),
        ).thenAnswer((_) async => '');
        when(
          () => mockStorage.read(key: TokenStorageKeys.refreshToken),
        ).thenAnswer((_) async => 'valid_refresh_token');

        // Act
        final result = await tokenStorage.hasValidTokens();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when refresh token is empty', () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.accessToken),
        ).thenAnswer((_) async => 'valid_access_token');
        when(
          () => mockStorage.read(key: TokenStorageKeys.refreshToken),
        ).thenAnswer((_) async => '');

        // Act
        final result = await tokenStorage.hasValidTokens();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when both tokens are null', () async {
        // Arrange
        when(
          () => mockStorage.read(key: TokenStorageKeys.accessToken),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorage.read(key: TokenStorageKeys.refreshToken),
        ).thenAnswer((_) async => null);

        // Act
        final result = await tokenStorage.hasValidTokens();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
