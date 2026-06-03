import 'package:injectable/injectable.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Use case for logging out the current user.
///
/// Invalidates the refresh token on the server and clears local token storage.
/// Validates: Requirement 1.11 (logout invalidates refresh token and clears storage).
@lazySingleton
class LogoutUseCase {
  /// Creates a [LogoutUseCase] with the given [repository].
  const LogoutUseCase(this.repository);

  /// The auth repository used to perform the logout operation.
  final AuthRepository repository;

  /// Executes the logout operation.
  Future<Result<void>> call() {
    return repository.logout();
  }
}
