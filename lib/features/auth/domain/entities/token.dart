import 'package:equatable/equatable.dart';

/// Represents JWT authentication tokens returned by the server.
///
/// Contains both the access token (short-lived, used for API requests)
/// and the refresh token (long-lived, used to obtain new access tokens).
class Token extends Equatable {
  /// Creates a [Token] with the given properties.
  const Token({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  /// The JWT access token used for authenticating API requests.
  final String accessToken;

  /// The refresh token used to obtain a new access token when it expires.
  /// Has a 30-day expiration and follows token rotation (single-use).
  final String refreshToken;

  /// The number of seconds until the access token expires (typically 3600).
  final int expiresIn;

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn];
}
