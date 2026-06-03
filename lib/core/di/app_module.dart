import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_constants.dart';

/// Module for registering external dependencies that cannot be
/// auto-injected via `@injectable` annotations.
///
/// This includes third-party library instances like Dio, SecureStorage,
/// and other platform-specific services.
@module
abstract class AppModule {
  /// Provides a configured [Dio] instance as a singleton.
  ///
  /// Configured with:
  /// - Base URL from [AppConstants.baseUrl]
  /// - Connection timeout from [AppConstants.connectTimeout]
  /// - Receive timeout from [AppConstants.receiveTimeout]
  ///
  /// Interceptors (Auth, TokenRefresh, Error, Connectivity, Logging)
  /// are added separately during DI registration of the ApiClient.
  @singleton
  Dio get dio => Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

  /// Provides a [FlutterSecureStorage] instance as a singleton.
  ///
  /// Uses platform-specific secure storage:
  /// - iOS: Keychain
  /// - Android: EncryptedSharedPreferences
  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );
}
