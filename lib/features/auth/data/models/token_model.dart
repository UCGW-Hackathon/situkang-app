import '../../domain/entities/token.dart';

/// Data Transfer Object for token API responses.
///
/// Parses the token data from login, register, and refresh endpoints.
/// Maps snake_case JSON fields to the domain [Token] entity.
class TokenModel {
  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  /// Parses a [TokenModel] from a JSON map (API response).
  ///
  /// Expects the `data` object from login/register/refresh responses
  /// containing `access_token`, `refresh_token`, and `expires_in`.
  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int? ?? 3600,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }

  /// The JWT access token for authenticating API requests.
  final String accessToken;

  /// The refresh token for obtaining new access tokens (token rotation).
  final String refreshToken;

  /// Seconds until the access token expires (typically 3600).
  final int expiresIn;

  /// The token type (always "Bearer").
  final String tokenType;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
    };
  }

  /// Converts this data model to the domain [Token] entity.
  Token toEntity() {
    return Token(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
  }
}
