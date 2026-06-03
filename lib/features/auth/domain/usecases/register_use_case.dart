import 'package:injectable/injectable.dart';
import '../../../../core/error/result.dart';
import '../entities/token.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for registering a new user account.
///
/// Creates a new account with the provided registration data and returns
/// the created [User] and JWT [Token] pair on success.
/// Validates: Requirement 1.1 (registration with valid data returns JWT tokens).
@lazySingleton
class RegisterUseCase {
  /// Creates a [RegisterUseCase] with the given [repository].
  const RegisterUseCase(this.repository);

  /// The auth repository used to perform the registration operation.
  final AuthRepository repository;

  /// Executes the registration operation with the given [params].
  Future<Result<(User, Token)>> call(RegisterParams params) {
    return repository.register(params: params);
  }
}
