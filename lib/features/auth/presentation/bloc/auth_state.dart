part of 'auth_bloc.dart';

/// Sealed class representing all authentication states.
///
/// The [AuthBloc] emits these states in response to [AuthEvent]s,
/// driving the UI to display the appropriate screen or feedback.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any authentication action has been taken.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State emitted while an authentication operation is in progress.
///
/// The UI should display a loading indicator when in this state.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State emitted when the user is successfully authenticated.
///
/// Contains the authenticated [User] entity with role and profile data.
class Authenticated extends AuthState {
  /// Creates an [Authenticated] state with the given [user].
  const Authenticated({required this.user});

  /// The authenticated user entity.
  final User user;

  @override
  List<Object?> get props => [user];
}

/// State emitted when the user is not authenticated.
///
/// This state is reached after:
/// - Successful logout (Requirement 1.11)
/// - Failed token refresh with expired/revoked refresh token (Requirement 1.9)
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// State emitted when an authentication operation fails.
///
/// Contains the [Failure] describing what went wrong, enabling the UI
/// to display appropriate error messages.
///
/// Handles:
/// - Invalid credentials (Requirement 1.7)
/// - Duplicate email/phone during registration (Requirements 1.2, 1.3)
/// - Network errors, server errors, etc.
class AuthError extends AuthState {
  /// Creates an [AuthError] state with the given [failure].
  const AuthError({required this.failure});

  /// The failure describing what went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// State emitted when a password reset email has been sent successfully.
///
/// Validates: Requirement 1.12 (password reset sends link to registered email).
class PasswordResetEmailSent extends AuthState {
  const PasswordResetEmailSent();
}

/// State emitted when a password has been successfully reset.
///
/// Validates: Requirement 1.13 (reset password with valid token updates password).
class PasswordResetSuccess extends AuthState {
  const PasswordResetSuccess();
}
