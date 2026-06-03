import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/constants/enums.dart';
import 'package:situkang_app/core/error/failures.dart';
import 'package:situkang_app/features/auth/domain/entities/token.dart';
import 'package:situkang_app/features/auth/domain/entities/user.dart';
import 'package:situkang_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:situkang_app/features/auth/domain/usecases/forgot_password_use_case.dart';
import 'package:situkang_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:situkang_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:situkang_app/features/auth/domain/usecases/refresh_token_use_case.dart';
import 'package:situkang_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:situkang_app/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:situkang_app/features/auth/presentation/bloc/auth_bloc.dart';

// Mocks
class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockRefreshTokenUseCase extends Mock implements RefreshTokenUseCase {}

class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}

class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockRefreshTokenUseCase mockRefreshTokenUseCase;
  late MockForgotPasswordUseCase mockForgotPasswordUseCase;
  late MockResetPasswordUseCase mockResetPasswordUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockRefreshTokenUseCase = MockRefreshTokenUseCase();
    mockForgotPasswordUseCase = MockForgotPasswordUseCase();
    mockResetPasswordUseCase = MockResetPasswordUseCase();

    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      logoutUseCase: mockLogoutUseCase,
      refreshTokenUseCase: mockRefreshTokenUseCase,
      forgotPasswordUseCase: mockForgotPasswordUseCase,
      resetPasswordUseCase: mockResetPasswordUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  // Test data
  final tUser = User(
    id: 'user-123',
    fullName: 'John Doe',
    email: 'john@example.com',
    phone: '+6281234567890',
    role: UserRole.user,
    createdAt: DateTime(2024, 1, 1),
  );

  const tToken = Token(
    accessToken: 'access-token-123',
    refreshToken: 'refresh-token-123',
    expiresIn: 3600,
  );

  const tRegisterParams = RegisterParams(
    fullName: 'John Doe',
    email: 'john@example.com',
    phone: '+6281234567890',
    password: 'Password1',
    passwordConfirmation: 'Password1',
    role: UserRole.user,
  );

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(const LoginParams(email: '', password: ''));
    registerFallbackValue(tRegisterParams);
    registerFallbackValue(const ForgotPasswordParams(email: ''));
    registerFallbackValue(
        const ResetPasswordParams(token: '', password: ''));
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    group('LoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when login succeeds',
        build: () {
          when(() => mockLoginUseCase(any()))
              .thenAnswer((_) async => Right((tUser, tToken)));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const LoginRequested(email: 'john@example.com', password: 'Password1'),
        ),
        expect: () => [
          const AuthLoading(),
          Authenticated(user: tUser),
        ],
        verify: (_) {
          verify(() => mockLoginUseCase(
                const LoginParams(
                    email: 'john@example.com', password: 'Password1'),
              )).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails with invalid credentials',
        build: () {
          when(() => mockLoginUseCase(any())).thenAnswer(
            (_) async => const Left(
              AuthFailure('Email atau password salah'),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const LoginRequested(email: 'john@example.com', password: 'wrong'),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            failure: AuthFailure('Email atau password salah'),
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails with network error',
        build: () {
          when(() => mockLoginUseCase(any())).thenAnswer(
            (_) async => const Left(NetworkFailure()),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const LoginRequested(email: 'john@example.com', password: 'Password1'),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(failure: NetworkFailure()),
        ],
      );
    });

    group('RegisterRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when registration succeeds',
        build: () {
          when(() => mockRegisterUseCase(any()))
              .thenAnswer((_) async => Right((tUser, tToken)));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterRequested(params: tRegisterParams),
        ),
        expect: () => [
          const AuthLoading(),
          Authenticated(user: tUser),
        ],
        verify: (_) {
          verify(() => mockRegisterUseCase(tRegisterParams)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when registration fails with duplicate email',
        build: () {
          when(() => mockRegisterUseCase(any())).thenAnswer(
            (_) async => const Left(
              ServerFailure(
                'Email sudah terdaftar',
                statusCode: 422,
                fieldErrors: [FieldError(field: 'email', message: 'Email sudah terdaftar')],
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterRequested(params: tRegisterParams),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            failure: ServerFailure(
              'Email sudah terdaftar',
              statusCode: 422,
              fieldErrors: [FieldError(field: 'email', message: 'Email sudah terdaftar')],
            ),
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when registration fails with duplicate phone',
        build: () {
          when(() => mockRegisterUseCase(any())).thenAnswer(
            (_) async => const Left(
              ServerFailure(
                'Nomor telepon sudah terdaftar',
                statusCode: 422,
                fieldErrors: [FieldError(field: 'phone', message: 'Nomor telepon sudah terdaftar')],
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterRequested(params: tRegisterParams),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            failure: ServerFailure(
              'Nomor telepon sudah terdaftar',
              statusCode: 422,
              fieldErrors: [FieldError(field: 'phone', message: 'Nomor telepon sudah terdaftar')],
            ),
          ),
        ],
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] when logout succeeds',
        build: () {
          when(() => mockLogoutUseCase())
              .thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [const Unauthenticated()],
        verify: (_) {
          verify(() => mockLogoutUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] even when logout API call fails',
        build: () {
          when(() => mockLogoutUseCase())
              .thenAnswer((_) async => const Left(NetworkFailure()));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [const Unauthenticated()],
      );
    });

    group('TokenRefreshRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits nothing when token refresh succeeds (maintains current state)',
        build: () {
          when(() => mockRefreshTokenUseCase())
              .thenAnswer((_) async => const Right(tToken));
          return authBloc;
        },
        act: (bloc) => bloc.add(const TokenRefreshRequested()),
        expect: () => <AuthState>[],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] when token refresh fails',
        build: () {
          when(() => mockRefreshTokenUseCase()).thenAnswer(
            (_) async => const Left(
              AuthFailure('Refresh token expired'),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const TokenRefreshRequested()),
        expect: () => [const Unauthenticated()],
      );
    });

    group('ForgotPasswordRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, PasswordResetEmailSent] when forgot password succeeds',
        build: () {
          when(() => mockForgotPasswordUseCase(any()))
              .thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const ForgotPasswordRequested(email: 'john@example.com'),
        ),
        expect: () => [
          const AuthLoading(),
          const PasswordResetEmailSent(),
        ],
        verify: (_) {
          verify(() => mockForgotPasswordUseCase(
                const ForgotPasswordParams(email: 'john@example.com'),
              )).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when forgot password fails',
        build: () {
          when(() => mockForgotPasswordUseCase(any())).thenAnswer(
            (_) async => const Left(
              ServerFailure('Server error', statusCode: 500),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const ForgotPasswordRequested(email: 'john@example.com'),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            failure: ServerFailure('Server error', statusCode: 500),
          ),
        ],
      );
    });

    group('ResetPasswordRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, PasswordResetSuccess] when reset password succeeds',
        build: () {
          when(() => mockResetPasswordUseCase(any()))
              .thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const ResetPasswordRequested(
            token: 'reset-token-123',
            password: 'NewPassword1',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const PasswordResetSuccess(),
        ],
        verify: (_) {
          verify(() => mockResetPasswordUseCase(
                const ResetPasswordParams(
                  token: 'reset-token-123',
                  password: 'NewPassword1',
                ),
              )).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when reset password fails with expired token',
        build: () {
          when(() => mockResetPasswordUseCase(any())).thenAnswer(
            (_) async => const Left(
              AuthFailure('Reset link sudah tidak berlaku'),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const ResetPasswordRequested(
            token: 'expired-token',
            password: 'NewPassword1',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            failure: AuthFailure('Reset link sudah tidak berlaku'),
          ),
        ],
      );
    });
  });
}
