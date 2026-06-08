import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

/// Abstract interface for the auth remote data source.
///
/// Defines API calls to the authentication endpoints.
/// Throws [DioException] on network/server errors which are
/// caught and mapped to [Failure] types in the repository layer.
abstract class AuthRemoteDataSource {
  /// Registers a new user account.
  ///
  /// Calls `POST /auth/register` with the registration data.
  /// Returns a record containing the [UserModel] and [TokenModel] on success.
  Future<(UserModel, TokenModel)> register(RegisterParams params);

  /// Authenticates a user with email and password.
  ///
  /// Calls `POST /auth/login` with credentials.
  /// Returns a record containing the [UserModel] and [TokenModel] on success.
  Future<(UserModel, TokenModel)> login({
    required String email,
    required String password,
  });

  /// Invalidates the current session on the server.
  ///
  /// Calls `POST /auth/logout` with the current access token.
  Future<void> logout();

  /// Refreshes the access token using a refresh token.
  ///
  /// Calls `POST /auth/refresh` with the refresh token.
  /// Returns a new [TokenModel] with rotated tokens.
  Future<TokenModel> refresh({required String refreshToken});

  /// Sends a password reset link to the specified email.
  ///
  /// Calls `POST /auth/forgot-password`.
  Future<void> forgotPassword({required String email});

  /// Resets the user's password using a valid reset token.
  ///
  /// Calls `POST /auth/reset-password`.
  Future<void> resetPassword({
    required String token,
    required String password,
  });
}

/// Implementation of [AuthRemoteDataSource] using [ApiClient].
@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<(UserModel, TokenModel)> register(RegisterParams params) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authRegister,
      data: {
        'full_name': params.fullName,
        'email': params.email,
        'phone': params.phone,
        'password': params.password,
        'password_confirmation': params.passwordConfirmation,
        'role': params.role.value,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final userModel = UserModel.fromJson(data);
    final tokenModel = TokenModel.fromJson(data);

    return (userModel, tokenModel);
  }

  @override
  Future<(UserModel, TokenModel)> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authLogin,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final userModel = UserModel.fromJson(data);
    final tokenModel = TokenModel.fromJson(data);

    return (userModel, tokenModel);
  }

  @override
  Future<void> logout() async {
    await apiClient.post<Map<String, dynamic>>(ApiEndpoints.authLogout);
  }

  @override
  Future<TokenModel> refresh({required String refreshToken}) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authRefresh,
      data: {
        'refresh_token': refreshToken,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return TokenModel.fromJson(data);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authForgotPassword,
      data: {
        'email': email,
      },
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authResetPassword,
      data: {
        'token': token,
        'password': password,
        'password_confirmation': password,
      },
    );
  }
}
