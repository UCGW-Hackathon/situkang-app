import 'package:injectable/injectable.dart';
import '../../../../core/storage/token_storage.dart';

/// Abstract interface for the auth local data source.
///
/// Handles local persistence of authentication tokens using
/// secure storage. Acts as a thin wrapper around [TokenStorage]
/// to maintain the data source abstraction in the data layer.
abstract class AuthLocalDataSource {
  /// Saves the access and refresh tokens to secure storage.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Retrieves the stored access token, or null if not present.
  Future<String?> getAccessToken();

  /// Retrieves the stored refresh token, or null if not present.
  Future<String?> getRefreshToken();

  /// Clears all stored tokens from secure storage.
  Future<void> clearTokens();

  /// Checks whether valid tokens exist in storage.
  Future<bool> hasValidTokens();
}

/// Implementation of [AuthLocalDataSource] using [TokenStorage].
///
/// Delegates all operations to the core [TokenStorage] abstraction
/// which uses platform-specific encrypted storage (Keychain on iOS,
/// EncryptedSharedPreferences on Android).
@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl({required this.tokenStorage});

  final TokenStorage tokenStorage;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    return tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<String?> getAccessToken() {
    return tokenStorage.getAccessToken();
  }

  @override
  Future<String?> getRefreshToken() {
    return tokenStorage.getRefreshToken();
  }

  @override
  Future<void> clearTokens() {
    return tokenStorage.clearTokens();
  }

  @override
  Future<bool> hasValidTokens() {
    return tokenStorage.hasValidTokens();
  }
}
