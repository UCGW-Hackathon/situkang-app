import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Parameters for the forgot password use case.
class ForgotPasswordParams extends Equatable {
  /// Creates [ForgotPasswordParams] with the required email.
  const ForgotPasswordParams({required this.email});

  /// The email address to send the password reset link to.
  final String email;

  @override
  List<Object?> get props => [email];
}

/// Use case for requesting a password reset email.
///
/// Sends a reset link to the registered email address.
/// Validates: Requirement 1.12 (password reset sends link to registered email).
@lazySingleton
class ForgotPasswordUseCase {
  /// Creates a [ForgotPasswordUseCase] with the given [repository].
  const ForgotPasswordUseCase(this.repository);

  /// The auth repository used to perform the forgot password operation.
  final AuthRepository repository;

  /// Executes the forgot password operation with the given [params].
  Future<Result<void>> call(ForgotPasswordParams params) {
    return repository.forgotPassword(email: params.email);
  }
}
