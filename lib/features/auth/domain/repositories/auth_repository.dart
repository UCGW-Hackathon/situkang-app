import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/error/result.dart';
import '../entities/token.dart';
import '../entities/user.dart';

/// Parameters required for user registration.
///
/// Encapsulates all fields needed to create a new account,
/// matching the API's registration endpoint requirements.
class RegisterParams extends Equatable {
  /// Creates [RegisterParams] with the required registration fields.
  const RegisterParams({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.role,
  });

  /// The user's full name (max 255 characters).
  final String fullName;

  /// The user's email address (must be unique and valid format).
  final String email;

  /// The user's phone number with country code (max 20 characters).
  final String phone;

  /// The user's password (min 8 chars, must contain uppercase, lowercase, digit).
  final String password;

  /// Must match [password] exactly.
  final String passwordConfirmation;

  /// The role for the new account (user or worker).
  final UserRole role;

  @override
  List<Object?> get props => [
        fullName,
        email,
        phone,
        password,
        passwordConfirmation,
        role,
      ];
}

/// Abstract repository defining authentication operations.
///
/// This interface is implemented in the data layer and consumed by
/// use cases in the domain layer. All methods return [Result] to
/// handle errors functionally without exceptions.
abstract class AuthRepository {
  /// Authenticates a user with email and password credentials.
  ///
  /// Returns the authenticated [User] and JWT [Token] pair on success.
  /// Returns [AuthFailure] for invalid credentials (without revealing which field).
  Future<Result<(User, Token)>> login({
    required String email,
    required String password,
  });

  /// Creates a new user account with the provided registration data.
  ///
  /// Returns the created [User] and JWT [Token] pair on success.
  /// Returns [ServerFailure] with field errors for duplicate email/phone.
  /// Returns [ValidationFailure] for invalid input data.
  Future<Result<(User, Token)>> register({
    required RegisterParams params,
  });

  /// Invalidates the current refresh token and clears local token storage.
  ///
  /// Returns void on success. The caller should transition to unauthenticated state.
  Future<Result<void>> logout();

  /// Requests a new access token using the stored refresh token.
  ///
  /// Implements token rotation: the old refresh token is invalidated and
  /// a new one is issued with a 30-day expiration.
  /// Returns [AuthFailure] if the refresh token is expired or revoked.
  Future<Result<Token>> refreshToken();

  /// Sends a password reset link to the specified email address.
  ///
  /// Returns void on success (reset email sent).
  /// Does not reveal whether the email exists in the system.
  Future<Result<void>> forgotPassword({required String email});

  /// Resets the user's password using a valid reset token.
  ///
  /// Returns void on success (password updated).
  /// Returns [AuthFailure] if the token is expired or already used.
  Future<Result<void>> resetPassword({
    required String token,
    required String password,
  });
}
