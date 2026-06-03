/// Implementation of [TokenStorage] using flutter_secure_storage.
///
/// Uses platform-specific encrypted storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences
///
/// Tokens are stored with constant keys and are never persisted in plain text.
///
/// Requirements: 27.1, 27.2, 27.3
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import 'token_storage.dart';

/// Constant keys used for storing tokens in secure storage.
///
/// Using constants prevents typos and makes key management centralized.
class TokenStorageKeys {
  TokenStorageKeys._();

  /// Key for the JWT access token.
  static const String accessToken = 'situkang_access_token';

  /// Key for the JWT refresh token.
  static const String refreshToken = 'situkang_refresh_token';
}

/// Secure implementation of [TokenStorage] backed by flutter_secure_storage.
///
/// On iOS, tokens are stored in the Keychain with default accessibility
/// settings. On Android, tokens are stored using EncryptedSharedPreferences
/// which leverages the Android Keystore system for key management.
@LazySingleton(as: TokenStorage)
class SecureTokenStorageImpl implements TokenStorage {
  /// Creates a [SecureTokenStorageImpl] with the given [FlutterSecureStorage].
  ///
  /// The [storage] parameter allows dependency injection for testing.
  SecureTokenStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? _createSecureStorage();

  final FlutterSecureStorage _storage;

  /// Creates a [FlutterSecureStorage] instance with platform-specific options.
  ///
  /// - iOS: Uses Keychain with default accessibility (accessible when unlocked).
  /// - Android: Uses EncryptedSharedPreferences for AES-256 encryption.
  static FlutterSecureStorage _createSecureStorage() {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: TokenStorageKeys.accessToken, value: accessToken),
      _storage.write(key: TokenStorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: TokenStorageKeys.accessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(key: TokenStorageKeys.refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: TokenStorageKeys.accessToken),
      _storage.delete(key: TokenStorageKeys.refreshToken),
    ]);
  }

  @override
  Future<bool> hasValidTokens() async {
    final results = await Future.wait([
      _storage.read(key: TokenStorageKeys.accessToken),
      _storage.read(key: TokenStorageKeys.refreshToken),
    ]);

    final accessToken = results[0];
    final refreshToken = results[1];

    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }
}
