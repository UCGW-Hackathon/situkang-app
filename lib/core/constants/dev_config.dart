/// Developer Configuration for SITUKANG app.
///
/// This file is used to load developer credentials and bypass configurations
/// from environment variables defined during build or run time.
class DevConfig {
  DevConfig._();

  /// Whether the developer login bypass is enabled.
  static const bool bypassEnabled = bool.fromEnvironment(
    'DEV_BYPASS_ENABLED',
  );

  /// The role to bypass as: 'user' or 'worker'.
  static const String bypassRole = String.fromEnvironment(
    'DEV_BYPASS_ROLE',
    defaultValue: 'user',
  );

  /// The developer email for User role login bypass.
  static const String userEmail = String.fromEnvironment(
    'DEV_USER_EMAIL',
  );

  /// The developer password for User role login bypass.
  static const String userPassword = String.fromEnvironment(
    'DEV_USER_PASSWORD',
  );

  /// The developer email for Worker role login bypass.
  static const String workerEmail = String.fromEnvironment(
    'DEV_WORKER_EMAIL',
  );

  /// The developer password for Worker role login bypass.
  static const String workerPassword = String.fromEnvironment(
    'DEV_WORKER_PASSWORD',
  );
}
