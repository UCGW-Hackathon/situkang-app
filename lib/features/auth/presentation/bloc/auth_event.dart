part of 'auth_bloc.dart';

/// Sealed class representing all authentication events.
///
/// Events are dispatched from the UI layer to trigger state changes
/// in the [AuthBloc].
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched when a user requests to log in.
///
/// Validates: Requirement 1.6 (login with valid credentials).
class LoginRequested extends AuthEvent {
  /// Creates a [LoginRequested] event with the given credentials.
  const LoginRequested({
    required this.email,
    required this.password,
  });

  /// The user's email address.
  final String email;

  /// The user's password.
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Event dispatched when a user requests to register a new account.
///
/// Validates: Requirement 1.1 (registration with valid data).
class RegisterRequested extends AuthEvent {
  /// Creates a [RegisterRequested] event with the given registration params.
  const RegisterRequested({required this.params});

  /// The registration parameters containing all required fields.
  final RegisterParams params;

  @override
  List<Object?> get props => [params];
}

/// Event dispatched when a user requests to log out.
///
/// Validates: Requirement 1.11 (logout invalidates refresh token).
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event dispatched when a token refresh is needed.
///
/// Validates: Requirement 1.9 (redirect to login on expired refresh token).
class TokenRefreshRequested extends AuthEvent {
  const TokenRefreshRequested();
}

/// Event dispatched when a user requests a password reset email.
///
/// Validates: Requirement 1.12 (send reset link to registered email).
class ForgotPasswordRequested extends AuthEvent {
  /// Creates a [ForgotPasswordRequested] event with the given email.
  const ForgotPasswordRequested({required this.email});

  /// The email address to send the reset link to.
  final String email;

  @override
  List<Object?> get props => [email];
}

/// Event dispatched when a user submits a new password with a reset token.
///
/// Validates: Requirement 1.13 (reset password with valid token).
class ResetPasswordRequested extends AuthEvent {
  /// Creates a [ResetPasswordRequested] event with the given token and password.
  const ResetPasswordRequested({
    required this.token,
    required this.password,
  });

  /// The password reset token received via email.
  final String token;

  /// The new password to set.
  final String password;

  @override
  List<Object?> get props => [token, password];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}
