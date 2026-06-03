import 'package:injectable/injectable.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/di/injection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/forgot_password_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/refresh_token_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import '../../domain/usecases/reset_password_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC responsible for managing authentication state.
///
/// Handles login, registration, logout, token refresh, forgot password,
/// and reset password flows. Maps domain failures to appropriate UI states.
///
/// Validates:
/// - Requirement 1.1: Registration with valid data
/// - Requirement 1.2: Duplicate email error
/// - Requirement 1.3: Duplicate phone error
/// - Requirement 1.6: Login with valid credentials
/// - Requirement 1.7: Invalid credentials error
/// - Requirement 1.9: Redirect to login on expired refresh token
/// - Requirement 1.11: Logout invalidates refresh token
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Creates an [AuthBloc] with the required use cases.
  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _refreshTokenUseCase = refreshTokenUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
  }

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  /// Handles [AuthCheckRequested] events.
  /// 
  /// Currently we don't have a GetUserUseCase. If tokens exist we could try 
  /// refresh, but for now we emit Unauthenticated to force login flow.
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Attempting to refresh token to see if session is valid. 
    // If we had a GetProfileUseCase, we would use it here.
    final result = await _refreshTokenUseCase();
    result.fold(
      (failure) => emit(const Unauthenticated()),
      (_) => emit(const Unauthenticated()), // Forces login since we don't have the User object
    );
  }

  /// Handles [LoginRequested] events.
  ///
  /// Emits [AuthLoading], then either [Authenticated] on success
  /// or [AuthError] on failure (e.g., invalid credentials per Requirement 1.7).
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure: failure)),
      (data) => emit(Authenticated(user: data.$1)),
    );
  }

  /// Handles [RegisterRequested] events.
  ///
  /// Emits [AuthLoading], then either [Authenticated] on success
  /// or [AuthError] on failure. Handles duplicate email (Requirement 1.2)
  /// and duplicate phone (Requirement 1.3) validation errors from the server.
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _registerUseCase(event.params);

    result.fold(
      (failure) => emit(AuthError(failure: failure)),
      (data) => emit(Authenticated(user: data.$1)),
    );
  }

  /// Handles [LogoutRequested] events.
  ///
  /// Calls the logout use case to invalidate the refresh token on the server
  /// and clear local storage, then emits [Unauthenticated].
  /// Per Requirement 1.11, always transitions to [Unauthenticated] regardless
  /// of whether the server call succeeds (tokens are cleared locally).
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(const Unauthenticated());
  }

  /// Handles [TokenRefreshRequested] events.
  ///
  /// Attempts to refresh the access token. On failure (expired/revoked refresh
  /// token per Requirement 1.9), emits [Unauthenticated] to redirect to login.
  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _refreshTokenUseCase();

    result.fold(
      (failure) => emit(const Unauthenticated()),
      (_) {
        // Token refreshed successfully; maintain current authenticated state.
        // The interceptor handles storing the new tokens.
      },
    );
  }

  /// Handles [ForgotPasswordRequested] events.
  ///
  /// Emits [AuthLoading], then either [PasswordResetEmailSent] on success
  /// or [AuthError] on failure.
  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _forgotPasswordUseCase(
      ForgotPasswordParams(email: event.email),
    );

    result.fold(
      (failure) => emit(AuthError(failure: failure)),
      (_) => emit(const PasswordResetEmailSent()),
    );
  }

  /// Handles [ResetPasswordRequested] events.
  ///
  /// Emits [AuthLoading], then either [PasswordResetSuccess] on success
  /// or [AuthError] on failure (e.g., expired/used token per Requirement 1.14).
  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _resetPasswordUseCase(
      ResetPasswordParams(token: event.token, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure: failure)),
      (_) => emit(const PasswordResetSuccess()),
    );
  }
}
