import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../entities/token.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Parameters for the login use case.
class LoginParams extends Equatable {
  /// Creates [LoginParams] with the required credentials.
  const LoginParams({
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

/// Use case for authenticating a user with email and password.
///
/// Returns the authenticated [User] and [Token] pair on success.
/// Validates: Requirement 1.6 (login with valid credentials returns JWT tokens).
@lazySingleton
class LoginUseCase {
  /// Creates a [LoginUseCase] with the given [repository].
  const LoginUseCase(this.repository);

  /// The auth repository used to perform the login operation.
  final AuthRepository repository;

  /// Executes the login operation with the given [params].
  Future<Result<(User, Token)>> call(LoginParams params) {
    return repository.login(
      email: params.email,
      password: params.password,
    );
  }
}
