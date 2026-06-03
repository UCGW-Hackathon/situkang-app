import 'package:injectable/injectable.dart';
import '../../../../core/error/result.dart';
import '../entities/token.dart';
import '../repositories/auth_repository.dart';

/// Use case for refreshing the access token.
///
/// Uses the stored refresh token to obtain a new access token and
/// implements token rotation (old refresh token is invalidated).
/// Validates: Requirement 1.8 (auto-refresh on expiry),
/// Requirement 1.10 (token rotation with 30-day refresh expiration).
@lazySingleton
class RefreshTokenUseCase {
  /// Creates a [RefreshTokenUseCase] with the given [repository].
  const RefreshTokenUseCase(this.repository);

  /// The auth repository used to perform the token refresh operation.
  final AuthRepository repository;

  /// Executes the token refresh operation.
  Future<Result<Token>> call() {
    return repository.refreshToken();
  }
}
