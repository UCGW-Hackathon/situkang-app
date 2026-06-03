/// Abstract interface for secure token storage.
///
/// Defines the contract for persisting and retrieving JWT authentication
/// tokens (access and refresh) in a secure manner. Implementations should
/// use platform-specific encrypted storage mechanisms.
///
/// Requirements: 27.1, 27.2, 27.3
library;

/// Abstract class defining the contract for secure token storage.
///
/// All methods are asynchronous since platform-specific secure storage
/// operations (Keychain on iOS, EncryptedSharedPreferences on Android)
/// are inherently asynchronous.
abstract class TokenStorage {
  /// Saves both the access token and refresh token to secure storage.
  ///
  /// Replaces any previously stored tokens with the new values.
  /// This is called after successful login, registration, or token refresh.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Retrieves the stored access token.
  ///
  /// Returns `null` if no access token is stored (e.g., user has never
  /// logged in or tokens have been cleared).
  Future<String?> getAccessToken();

  /// Retrieves the stored refresh token.
  ///
  /// Returns `null` if no refresh token is stored (e.g., user has never
  /// logged in or tokens have been cleared).
  Future<String?> getRefreshToken();

  /// Clears all stored tokens from secure storage.
  ///
  /// Called when the user logs out, when the refresh token expires or is
  /// revoked, or when a token refresh attempt fails.
  Future<void> clearTokens();

  /// Checks whether valid tokens exist in storage.
  ///
  /// Returns `true` if both an access token and a refresh token are present
  /// in secure storage. Note: this does not validate token expiration — it
  /// only checks for the presence of stored values.
  Future<bool> hasValidTokens();
}
