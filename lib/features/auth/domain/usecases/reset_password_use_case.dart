import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Parameters for the reset password use case.
class ResetPasswordParams extends Equatable {
  /// Creates [ResetPasswordParams] with the required fields.
  const ResetPasswordParams({
    required this.token,
    required this.password,
  });

  /// The password reset token received via email.
  final String token;

  /// The new password to set (must meet password requirements).
  final String password;

  @override
  List<Object?> get props => [token, password];
}

/// Use case for resetting a user's password with a valid reset token.
///
/// Updates the password and confirms success.
/// Validates: Requirement 1.13 (reset password with valid token updates password).
@lazySingleton
class ResetPasswordUseCase {
  /// Creates a [ResetPasswordUseCase] with the given [repository].
  const ResetPasswordUseCase(this.repository);

  /// The auth repository used to perform the password reset operation.
  final AuthRepository repository;

  /// Executes the reset password operation with the given [params].
  Future<Result<void>> call(ResetPasswordParams params) {
    return repository.resetPassword(
      token: params.token,
      password: params.password,
    );
  }
}
